//
//  File.swift
//  File
//
//  Created by Xiangyue Meng on 2021/9/3.
//

import Foundation
import EtcdProto
import NIO
import GRPC

typealias WatchClient = Etcdserverpb_WatchClient

public typealias WatchRequest = Etcdserverpb_WatchRequest
public typealias WatchResponse = Etcdserverpb_WatchResponse

public typealias WatchCreateRequest = Etcdserverpb_WatchCreateRequest
public typealias WatchCancelRequest = Etcdserverpb_WatchCancelRequest
public typealias WatchProgressRequest = Etcdserverpb_WatchProgressRequest


public class Watcher {
  private let streamingCall: BidirectionalStreamingCall<WatchRequest, WatchResponse>
  private let listener: WatchListener
  private var closed = false // TODO: private final AtomicBoolean closed;
  private var watchId: Int64? = nil
  
  fileprivate var uuid: UUID = UUID()
  
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
  
  private let watchHandlerWrapper: WatchHandlerWrapper
  private let onClose: ((UUID) -> ())?
  
  init(client: WatchClient, request: WatchRequest, listener: WatchListener, onClose: ((UUID) -> ())? = nil) {
    let watchHandlerWrapper = WatchHandlerWrapper { watcher, response in
      watcher?.onReceive(response: response)
    }
    
    /// can't use handler directly, because we will use self to do something, but can't init in this way. so use the wrapper to do this.
    self.streamingCall = client.watch(callOptions: CallOptions(), handler: watchHandlerWrapper.etcdWatchHandler)
    self.listener = listener
    self.watchHandlerWrapper = watchHandlerWrapper
    self.onClose = onClose
    
    watchHandlerWrapper.watcher = self
    
    streamingCall.sendMessage(request, promise: nil)
    streamingCall.status.whenSuccess { [weak self] status in
      if status.code == .ok {
        self?.listener.onCompleted()
      } else {
        self?.listener.onError(error: status) // TODO: specify the error
      }
    }
  }
  
  private func onReceive(response: WatchResponse) {
    // events eventually received when the client is closed should
    // not be propagated to the listener
    guard closed == false else {
      return
    }
    // TODO: 
  }
  
  func close() -> EventLoopFuture<Void> {
    self.closed = true
    let request = WatchRequest.with {
      $0.cancelRequest = WatchCancelRequest()
    }
    
    self.streamingCall.sendMessage(request, promise: nil)
    listener.onCompleted()
    self.onClose?(self.uuid)
    return self.streamingCall.sendEnd()
  }
  
  func requestProgress() {
    let request = WatchRequest.with {
      $0.progressRequest = Etcdserverpb_WatchProgressRequest()
    }
    streamingCall.sendMessage(request, promise: nil)
  }
}

public protocol WatchListener {
  func onNext(response: WatchResponse)
  func onError(error: Error)
  func onCompleted()
}

public class Watch {
  private let client: WatchClient
  private let retryManager: RetryManager
  
  private var watchers: [Watcher] = []
  
  init(client: WatchClient, retryManager: RetryManager) {
    self.client = client
    self.retryManager = retryManager
  }
  
  public func watch(request: WatchCreateRequest, listener: WatchListener) -> Watcher {
    let r = WatchRequest.with {
      $0.createRequest = request
    }
    let watcher = Watcher(client: self.client, request: r, listener: listener) { [weak self] uuid in
      // TODO: remove watcher with lock
      self?.watchers.removeAll { $0.uuid == uuid }
    }
    self.watchers.append(watcher)
    return watcher
  }
  
  public func close() {
    
  }
}
