//
//  File.swift
//  File
//
//  Created by Xiangyue Meng on 2021/9/3.
//

import Foundation
import NIO
import GRPC
import NIOConcurrencyHelpers
import EtcdProto

typealias LeaseClient = Etcdserverpb_LeaseClient

public typealias LeaseGrantRequest = Etcdserverpb_LeaseGrantRequest
public typealias LeaseGrantResponse = Etcdserverpb_LeaseGrantResponse

public typealias LeaseRevokeRequest = Etcdserverpb_LeaseRevokeRequest
public typealias LeaseRevokeResponse = Etcdserverpb_LeaseRevokeResponse

public typealias LeaseKeepAliveRequest = Etcdserverpb_LeaseKeepAliveRequest
public typealias LeaseKeepAliveResponse = Etcdserverpb_LeaseKeepAliveResponse

public typealias LeaseTimeToLiveRequest = Etcdserverpb_LeaseTimeToLiveRequest
public typealias LeaseTimeToLiveResponse = Etcdserverpb_LeaseTimeToLiveResponse


public class Lease {
  private let client: LeaseClient
  private let retryManager: RetryManager
  private let eventLoop: EventLoop
  
  private var hasKeepAliveServiceStarted = false
  private var keepAliveRepeatedTask: RepeatedTask? = nil
  private var deadlineClearRepeatedTask: RepeatedTask? = nil
  
  private var keepAliveMap: [Int64: KeepAlive] = [:]
  
  init(client: LeaseClient, retryManager: RetryManager, eventLoop: EventLoop) {
    self.client = client
    self.retryManager = retryManager
    self.eventLoop = eventLoop
  }
  
  public func grant(ttl: Int64, timeout: TimeAmount? = nil) -> EventLoopFuture<LeaseGrantResponse> {
    let request = LeaseGrantRequest.with {
      $0.ttl = ttl
    }
    return self.retryManager.execute { callOptions in
      var options = callOptions
      if let timeout = timeout {
        options.timeLimit = .timeout(timeout)
      }
      return self.client.leaseGrant(request, callOptions: options).response
    }
  }
  
  public func revoke(leaseId: Int64) -> EventLoopFuture<LeaseRevokeResponse> {
    let request = LeaseRevokeRequest.with {
      $0.id = leaseId
    }
    return self.retryManager.execute { callOptions in
      return self.client.leaseRevoke(request, callOptions: callOptions).response
    }
  }
  
  public func keepAliveOnce(leaseId: Int64) -> EventLoopFuture<LeaseKeepAliveResponse> {
    let promise = eventLoop.makePromise(of: LeaseKeepAliveResponse.self)
    let request = LeaseKeepAliveRequest.with {
      $0.id = leaseId
    }
    // TODO: is there a case of permission denied.
    let streamingCall = self.client.leaseKeepAlive(callOptions: retryManager.callOptions) { response in
      promise.succeed(response)
    }
    streamingCall.status.whenSuccess { status in
      if status.code != .ok {
        promise.fail(EtcdError.from(grpcStatus: status))
      }
    }
    _ = streamingCall.sendMessage(request)
    _ = streamingCall.sendEnd()
    return promise.futureResult
  }
  
  public func timeToLive(leaseId: Int64, isAttachedKeys: Bool) -> EventLoopFuture<LeaseTimeToLiveResponse> {
    let request = LeaseTimeToLiveRequest.with {
      $0.id = leaseId
      $0.keys = isAttachedKeys
    }
    return self.retryManager.execute { callOptions in
      return self.client.leaseTimeToLive(request, callOptions: callOptions).response
    }
  }
  
  
  // TODO:
  public func keepAlive(leaseId: Int64, listener: KeepAliveLister) -> CloseableClient {
    // TODO: - reuse same KeepAlive
    let listenerWrapper = KeepAliveListerWrapper(listener: listener)
    let keepAlive = keepAliveMap[leaseId] ?? KeepAlive(client: client,
                                                        leaseId: leaseId,
                                                        listener: listenerWrapper,
                                                        retryManager: retryManager,
                                                        removeSelfFromParent: { [weak self] in self?.keepAliveMap[$0] = nil })
    keepAlive.start()
    keepAliveMap[leaseId] = keepAlive
    if hasKeepAliveServiceStarted == false {
      hasKeepAliveServiceStarted = true
      startKeepAliveRepeatTask()
      startDeadlineClearRepeatTask()
    }
    return DefaultKeepAliveCloseableClient {
      keepAlive.listenerArray.removeAll { $0.uuid == listenerWrapper.uuid }
    }
  }
  
  private func startKeepAliveRepeatTask() {
    let promise = eventLoop.makePromise(of: Void.self)
    promise.futureResult.whenComplete { reuslt in
      print("keepAliveRepeatedTask complete=\(reuslt)")
    }
    keepAliveRepeatedTask = eventLoop.scheduleRepeatedTask(initialDelay: .zero, delay: .milliseconds(500), notifying: promise) { [weak self] task in
      guard let this = self else { return }
      _ = this.keepAliveMap
        .filter({ $0.value.nextKeepAlive < Date().millisecondsSince1970 })
        .map({ $0.value.sendKeepAliveRequest() })
    }
  }
  
  private func startDeadlineClearRepeatTask() {
    deadlineClearRepeatedTask =  eventLoop.scheduleRepeatedTask(initialDelay: .zero, delay: .milliseconds(1000), notifying: nil) { [weak self] task in
      guard let this = self else { return }
      let now = Date().millisecondsSince1970
      this.keepAliveMap = this.keepAliveMap.filter {
        if $0.value.deadline < now {
          $0.value.close()
          return false
        }
        return true
      }
    }
  }
}

public protocol KeepAliveLister {
  func onNext(response: LeaseKeepAliveResponse)
  func onError(_ error: EtcdError)
  func onCompleted()
}

private class KeepAliveListerWrapper: KeepAliveLister {
  var uuid: UUID = UUID()
  private let sourceListener: KeepAliveLister
  init(listener: KeepAliveLister) {
    self.sourceListener = listener
  }
  func onNext(response: LeaseKeepAliveResponse) { sourceListener.onNext(response: response) }
  func onError(_ error: EtcdError) { sourceListener.onError(error) }
  func onCompleted() { sourceListener.onCompleted() }
}

public class DefaultKeepAliveCloseableClient: CloseableClient {
  private var closeClosure: (() -> ())
  init(closeClosure: @escaping () -> ()) {
    self.closeClosure = closeClosure
  }
  
  public func close() {
    closeClosure()
  }
}

private class KeepAlive {
  private let client: LeaseClient
  private let leaseId: Int64
  fileprivate var listenerArray: [KeepAliveListerWrapper] = []
  private let retryManager: RetryManager
  private var closed = NIOAtomic.makeAtomic(value: false)
  
  private let removeSelfFromParent: (Int64) -> ()
  
  var deadline: Int64
  var nextKeepAlive: Int64
 
  
  private var streamingCall: BidirectionalStreamingCall<Etcdserverpb_LeaseKeepAliveRequest, Etcdserverpb_LeaseKeepAliveResponse>? = nil
  
  
  fileprivate init(client: LeaseClient,
                   leaseId: Int64,
                   listener: KeepAliveListerWrapper,
                   retryManager: RetryManager,
                   removeSelfFromParent: @escaping (Int64) -> ()) {
    self.client = client
    self.leaseId = leaseId
    self.listenerArray.append(listener)
    self.nextKeepAlive = Date().millisecondsSince1970
    self.deadline = Date().millisecondsSince1970 + 5000
    self.retryManager = retryManager
    self.removeSelfFromParent = removeSelfFromParent
  }
  
  fileprivate func start() {
    guard streamingCall == nil else { return }
    let streamingCall = self.client.leaseKeepAlive(callOptions: retryManager.callOptions) { [weak self] response in
      guard let this = self else { return }
      guard this.closed.load() == false else {
        return
      }
      if response.ttl > 0 {
        this.nextKeepAlive = Date().millisecondsSince1970 + response.ttl * 1000 / 3
        this.deadline = Date().millisecondsSince1970 + response.ttl * 1000
        _ = this.listenerArray.map { $0.onNext(response: response)}
      } else {
        // TODO: -
        this.removeSelfFromParent(this.leaseId)
        _ = this.listenerArray.map { $0.onError(EtcdError(code: .notFound, message: "etcdserver: requested lease not found")) }
      }
    }
    streamingCall.status.whenSuccess { [weak self] status in
      guard let this = self else { return }
      if status.code != .ok {
        _ = this.listenerArray.map { $0.onError(EtcdError.from(grpcStatus: status)) }
      }
    }
    self.streamingCall = streamingCall
  }
  
  @discardableResult
  fileprivate func sendKeepAliveRequest() -> EventLoopFuture<Void>? {
    let request = LeaseKeepAliveRequest.with {
      $0.id = leaseId
    }
    return streamingCall?.sendMessage(request)
  }
  
  fileprivate func close() {
    _ = listenerArray.map {
      $0.onCompleted()
    }
  }
}

extension Date {
  var millisecondsSince1970: Int64 {
    return Int64(timeIntervalSince1970 * 1000)
  }
}
