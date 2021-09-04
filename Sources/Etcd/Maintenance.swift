//
//  File.swift
//  File
//
//  Created by Xiangyue Meng on 2021/9/3.
//

import Foundation
import NIO
import EtcdProto

typealias MaintenanceClient = Etcdserverpb_MaintenanceClient

public typealias AlarmRequest = Etcdserverpb_AlarmRequest
public typealias AlarmResponse = Etcdserverpb_AlarmResponse

public typealias DefragmentRequest = Etcdserverpb_DefragmentRequest
public typealias DefragmentResponse = Etcdserverpb_DefragmentResponse

public typealias StatusRequest = Etcdserverpb_StatusRequest
public typealias StatusResponse = Etcdserverpb_StatusResponse

public typealias HashKVRequest = Etcdserverpb_HashKVRequest
public typealias HashKVResponse = Etcdserverpb_HashKVResponse

public typealias MoveLeaderRequest = Etcdserverpb_MoveLeaderRequest
public typealias MoveLeaderResponse = Etcdserverpb_MoveLeaderResponse


public class Maintenance {
  private let client: MaintenanceClient
  private let retryManager: RetryManager
  
  init(client: MaintenanceClient, retryManager: RetryManager) {
    self.client = client
    self.retryManager = retryManager
  }
  
  public func listAlarms() -> EventLoopFuture<AlarmResponse> {
    let request = AlarmRequest.with {
      $0.alarm = .none
      $0.action = .get
      $0.memberID = 0
    }
    return self.retryManager.execute { callOptions in
      return self.client.alarm(request, callOptions: callOptions).response
    }
  }
  
  public func alarmDisarm(memberID: UInt64) -> EventLoopFuture<AlarmResponse> {
    let request = AlarmRequest.with {
      $0.alarm = .nospace
      $0.action = .deactivate
      $0.memberID = memberID
    }
    return self.retryManager.execute { callOptions in
      return self.client.alarm(request, callOptions: callOptions).response
    }
  }
  
  // TODO: why use new channel
  public func defragmentMember(endpoint: URL) -> EventLoopFuture<DefragmentResponse> {
    fatalError()
  }
  
  // TODO: why use new channel
  public func statusMember(endpoint: URL) -> EventLoopFuture<StatusResponse> {
    fatalError()
  }
  
  public func moveLeader(transfereeID: UInt64) -> EventLoopFuture<MoveLeaderResponse> {
    let request = MoveLeaderRequest.with {
      $0.targetID = transfereeID
    }
    return self.retryManager.execute { callOptions in
      return self.client.moveLeader(request, callOptions: callOptions).response
    }
  }
  
  public func hashKV(endpoint: UInt64, revision: Int64) -> EventLoopFuture<HashKVResponse> {
    let request = HashKVRequest.with {
      $0.revision = revision
    }
    return self.retryManager.execute { callOptions in
      return self.client.hashKV(request, callOptions: callOptions).response
    }
  }
  
  // TODO:
  public func snapshot() {
    
  }
  
  
}
