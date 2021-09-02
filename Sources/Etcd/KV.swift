//
//  File.swift
//  File
//
//  Created by xiangyue on 2021/8/26.
//

import Foundation
import NIO
import EtcdProto
import GRPC
import NIOHPACK

public typealias PutRequest = Etcdserverpb_PutRequest
public typealias PutResponse = Etcdserverpb_PutResponse

public typealias RangeRequest = Etcdserverpb_RangeRequest
public typealias RangeResponse = Etcdserverpb_RangeResponse

public typealias DeleteRangeRequest = Etcdserverpb_DeleteRangeRequest
public typealias DeleteRangeResponse = Etcdserverpb_DeleteRangeResponse

public typealias CompactionRequest = Etcdserverpb_CompactionRequest
public typealias CompactionResponse = Etcdserverpb_CompactionResponse

public class KV {
  private let client: Etcdserverpb_KVClient
  private let retryManager: RetryManager
  
  init(client: Etcdserverpb_KVClient, retryManager: RetryManager) {
    self.client = client
    self.retryManager = retryManager
  }
  
  // MARK: - PUT
  public func put(key: String, value: String) throws -> EventLoopFuture<PutResponse> {
    guard let keyData = key.data(using: .utf8), let valueData = value.data(using: .utf8) else {
      throw EtcdError.dataFormatIsWrong
    }
    let request = PutRequest.with {
      $0.key = keyData
      $0.value = valueData
    }
    return put(request: request)
  }
  
  public func put(request: PutRequest) -> EventLoopFuture<PutResponse> {
    let callOptions = CallOptions()
    return retryManager.execute(callOptions: callOptions) { callOptions in
      return self.client.put(request, callOptions: callOptions).response
    }
  }
  
  // MARK: - GET
  public func get(key: String) throws -> EventLoopFuture<RangeResponse> {
    guard let keyData = key.data(using: .utf8) else {
      throw EtcdError.dataFormatIsWrong
    }
    return get(key: keyData)
  }
  
  public func get(key: Data) -> EventLoopFuture<RangeResponse> {
    let request = RangeRequest.with {
      $0.key = key
    }
    return self.get(request: request)
  }
  
  public func get(request: RangeRequest) -> EventLoopFuture<RangeResponse> {
    self.retryManager.execute { callOptions in
      return self.client.range(request, callOptions: callOptions).response
    }
  }
  
  // MARK: - DELETE
  public func delete(key: String) throws -> EventLoopFuture<DeleteRangeResponse> {
    guard let keyData = key.data(using: .utf8) else {
      throw EtcdError.dataFormatIsWrong
    }
    return self.delete(key: keyData)
  }
  
  public func delete(key: Data) -> EventLoopFuture<DeleteRangeResponse> {
    let request = DeleteRangeRequest.with {
      $0.key = key
    }
    return self.delete(request: request)
  }
  
  public func delete(request: DeleteRangeRequest) -> EventLoopFuture<DeleteRangeResponse> {
    self.retryManager.execute { callOptions in
      return self.client.deleteRange(request, callOptions: callOptions).response
    }
  }
  
  // MARK: - COMPACT
  public func compact(revision: Int64) -> EventLoopFuture<CompactionResponse> {
    let request = CompactionRequest.with {
      $0.revision = revision
    }
    return self.compact(request: request)
  }
  
  public func compact(request: CompactionRequest) -> EventLoopFuture<CompactionResponse> {
    self.retryManager.execute { callOptions in
      return self.client.compact(request, callOptions: callOptions).response
    }
  }
}



