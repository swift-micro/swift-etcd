//
//  File.swift
//  File
//
//  Created by Xiangyue Meng on 2021/9/3.
//

import Foundation
import NIO
import NIOConcurrencyHelpers
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

public typealias SnapshotRequest = Etcdserverpb_SnapshotRequest
public typealias SnapshotResponse = Etcdserverpb_SnapshotResponse

public class Maintenance {
  private let client: MaintenanceClient
  private let retryManager: RetryManager
  private let eventLoop: EventLoop
  
  init(client: MaintenanceClient, retryManager: RetryManager, eventLoop: EventLoop) {
    self.client = client
    self.retryManager = retryManager
    self.eventLoop = eventLoop
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
    let request = DefragmentRequest()
    return retryManager.execute { callOptions in
      return self.client.defragment(request, callOptions: callOptions).response
    }
  }
  
  // TODO: why use new channel
  public func statusMember(endpoint: URL) -> EventLoopFuture<StatusResponse> {
    let request = StatusRequest()
    return retryManager.execute { callOptions in
      return self.client.status(request, callOptions: callOptions).response
    }
  }
  
  public func moveLeader(transfereeID: UInt64) -> EventLoopFuture<MoveLeaderResponse> {
    let request = MoveLeaderRequest.with {
      $0.targetID = transfereeID
    }
    return self.retryManager.execute { callOptions in
      return self.client.moveLeader(request, callOptions: callOptions).response
    }
  }
  
  // TODO: why use new channel
  public func hashKV(endpoint: UInt64, revision: Int64) -> EventLoopFuture<HashKVResponse> {
    let request = HashKVRequest.with {
      $0.revision = revision
    }
    return self.retryManager.execute { callOptions in
      return self.client.hashKV(request, callOptions: callOptions).response
    }
  }
  
  public func snapshot(outputStream: OutputStream) -> EventLoopFuture<Int64> {
    let request = SnapshotRequest()
    let promise = eventLoop.makePromise(of: Int64.self)
    let byteCount = NIOAtomic.makeAtomic(value: 0)
    let serverStreamingCall = client.snapshot(request, callOptions: retryManager.callOptions) { response in
      response.blob.withUnsafeBytes { rawBufferPointer in
        let bufferPointer = rawBufferPointer.bindMemory(to: UInt8.self)
        outputStream.write(bufferPointer.baseAddress!, maxLength: response.blob.count)
      }
      byteCount.add(response.blob.count)
    }
    serverStreamingCall.status.whenSuccess { status in
      if status.code == .ok {
        promise.succeed(Int64(byteCount.load()))
      } else {
        promise.fail(EtcdError.from(grpcStatus: status))
      }
    }
    return promise.futureResult
  }
  
  public func snapshot<T>(listener: T) where T: EtcdResponseListener, T.ResponseType == SnapshotResponse {
    let request = SnapshotRequest()
    let serverStreamingCall = client.snapshot(request, callOptions: retryManager.callOptions) { response in
      listener.onNext(response: response)
    }
    serverStreamingCall.status.whenSuccess { status in
      if status.code == .ok {
        listener.onCompleted()
      } else {
        listener.onError(EtcdError.from(grpcStatus: status))
      }
    }
  }
}

public protocol EtcdResponseListener {
  associatedtype ResponseType
  func onNext(response: ResponseType)
  func onError(_ error: EtcdError)
  func onCompleted()
}
