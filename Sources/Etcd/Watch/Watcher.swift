//
//  File.swift
//  File
//
//  Created by xiangyue on 2021/9/4.
//

import Foundation
import EtcdProto
import NIO
import GRPC
import NIOConcurrencyHelpers

// TODO: close resource for some error, refer to `handleError(EtcdException`
public class Watcher {
  private let retryManager: RetryManager
  private let client: WatchClient
  private var request: WatchRequest
  private var streamingCall: BidirectionalStreamingCall<WatchRequest, WatchResponse>
  private let listener: WatchListener
  
  private var closed = NIOAtomic.makeAtomic(value: false)
  private var watchId: Int64? = nil
  private var revision: Int64 = 0 // TODO: 重新赋值
  private let isProgressNotify: Bool
  
  var uuid: UUID = UUID()
  
  private let watchHandlerWrapper: WatchHandlerWrapper
  private let onClose: ((UUID) -> ())?
  
  init(client: WatchClient,
       request: WatchRequest,
       listener: WatchListener,
       retryManager: RetryManager,
       onClose: ((UUID) -> ())? = nil) {
    
    self.client = client
    self.request = request
    self.listener = listener
    self.retryManager = retryManager
    self.onClose = onClose
    
    let watchHandlerWrapper = WatchHandlerWrapper { watcher, response in
      watcher?.onReceive(response: response)
    }
    self.watchHandlerWrapper = watchHandlerWrapper
    self.isProgressNotify = request.createRequest.progressNotify
    
    self.streamingCall = Watcher.createStreamingCall(
      client: client,
      request: request,
      retryManager: retryManager,
      watchHandlerWrapper: watchHandlerWrapper,
      listener: listener)
    
    watchHandlerWrapper.watcher = self
  }
  
  private static func createStreamingCall(client: WatchClient,
                                          request: WatchRequest,
                                          retryManager: RetryManager,
                                          watchHandlerWrapper: WatchHandlerWrapper,
                                          listener: WatchListener) -> BidirectionalStreamingCall<WatchRequest, WatchResponse> {
    /// can't use handler directly, because we will use self to do something, but can't init in this way. so use the wrapper to do this.
    let streamingCall = client.watch(callOptions: retryManager.callOptions, handler: watchHandlerWrapper.etcdWatchHandler)
    streamingCall.sendMessage(request, promise: nil)
    streamingCall.status.whenSuccess { status in
      if status.code == .ok {
       listener.onCompleted()
      } else {
        // TODO: - clear resource
        listener.onError(EtcdError.from(grpcStatus: status))
      }
    }
    return streamingCall
  }
  
  private func onReceive(response: WatchResponse) {
    // events eventually received when the client is closed should
    // not be propagated to the listener
    guard self.closed.load() == false else {
      return
    }
    
    if response.created, response.canceled, response.cancelReason.contains("etcdserver: permission denied") {
      // potentially access token expired
      // TODO: - clear resource
      guard let future = retryManager.generateToken() else {
        listener.onError(EtcdError(code: .noAuthInfo, message: "Can't find user and password, but need to auth"))
        return
      }
      future.whenComplete { [weak self] result in
        guard let this = self else {
          return
        }
        switch result {
        case .success: // in retryManager already update the token
          this.streamingCall = Watcher.createStreamingCall(
            client: this.client,
            request: this.request,
            retryManager: this.retryManager,
            watchHandlerWrapper: this.watchHandlerWrapper,
            listener: this.listener)
        case .failure(let error):
          // TODO: need to update
          this.listener.onError(EtcdError(code: .unauthenticated, message: "Can't find user and password, but need to auth"))
          break
        }
      }
    } else if response.created {
      if response.watchID == -1 {
        listener.onError(EtcdError(code: .internalError, message: "etcd server failed to create watch id"))
        return;
      }
      self.revision = max(self.revision, response.header.revision)
      self.watchId = response.watchID
    } else if response.canceled {
      let reason = response.cancelReason
      let error: EtcdError
      if response.compactRevision != 0 {
        error = EtcdError(code: .outOfRange, message: "etcdserver: mvcc: required revision has been compacted(\(response.compactRevision)")
      } else if response.cancelReason.isEmpty {
        error = EtcdError(code: .outOfRange, message: "etcdserver: mvcc: required revision is a future revision")
      } else {
        error = EtcdError(code: .failedPrecondition, message: reason)
      }
      listener.onError(error)
      // TODO: - clear resource
    } else if response.isProgressNotify {
      listener.onNext(response: response)
      revision = max(self.revision, response.header.revision)
    } else if response.events.count == 0 && isProgressNotify {
      listener.onNext(response: response)
      revision = response.header.revision
    } else if response.events.count > 0 {
      listener.onNext(response: response)
      if let modRevision = response.events.last?.kv.modRevision {
        revision = modRevision + 1
      }
    }
    // TODO:
  }
  
  @discardableResult
  func close() -> EventLoopFuture<Void>? {
    self.closed.store(true)
    if self.closed.compareAndExchange(expected: false, desired: true) {
      if watchId != -1 {
        let request = WatchRequest.with {
          $0.cancelRequest = WatchCancelRequest()
        }
        
        self.streamingCall.sendMessage(request, promise: nil)
      }
      listener.onCompleted()
      self.onClose?(self.uuid)
      return self.streamingCall.sendEnd()
    }
    return nil
  }
  
  func requestProgress() {
    let request = WatchRequest.with {
      $0.progressRequest = Etcdserverpb_WatchProgressRequest()
    }
    streamingCall.sendMessage(request, promise: nil)
  }
  
  deinit {
    _ = streamingCall.sendEnd()
  }
}

extension Watcher {
  class WatchHandlerWrapper {
    weak var watcher: Watcher?
    var handler: (_ watcher: Watcher?, _ response: WatchResponse) -> Void
    
    lazy var etcdWatchHandler: (WatchResponse) -> Void = { [weak self] response in
      guard let this = self else { return }
      this.handler(this.watcher, response)
    }
    
    init(handler: @escaping (Watcher?, WatchResponse) -> Void) {
      self.handler = handler
    }
  }
}
