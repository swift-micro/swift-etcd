//
//  File.swift
//  File
//
//  Created by Xiangyue Meng on 2021/9/3.
//

import Foundation
import NIO
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
    let request = LeaseKeepAliveRequest.with {
      $0.id = leaseId
    }
    // TODO:
    fatalError()
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
  public func keepAlive(leaseId: Int64, handler: @escaping (LeaseKeepAliveResponse) -> Void) {
//    self.eventLoop.scheduleRepeatedTask(initialDelay: .zero, delay: .milliseconds(500), notifying: <#T##EventLoopPromise<Void>?#>, <#T##task: (RepeatedTask) throws -> Void##(RepeatedTask) throws -> Void#>)
  }
}
