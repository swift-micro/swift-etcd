//
//  File.swift
//  File
//
//  Created by Xiangyue Meng on 2021/9/3.
//

import Foundation
import EtcdProto
import NIO

typealias LockClient = V3lockpb_LockClient

public typealias LockRequest = V3lockpb_LockRequest
public typealias LockResponse = V3lockpb_LockResponse

public typealias UnlockRequest = V3lockpb_UnlockRequest
public typealias UnlockResponse = V3lockpb_UnlockResponse

public class EtcdLock {
  private let client: LockClient
  private let retryManager: RetryManager
  
  init(client: LockClient, retryManager: RetryManager) {
    self.client = client
    self.retryManager = retryManager
  }
  
  public func lock(name: String, leaseId: Int64) -> EventLoopFuture<LockResponse> {
    let request = LockRequest.with {
      $0.name = Data(name.utf8)
      $0.lease = leaseId
    }
    return self.retryManager.execute { callOptions in
      return self.client.lock(request, callOptions: callOptions).response
    }
  }
  
  public func unlock(key: String) -> EventLoopFuture<UnlockResponse> {
    let request = UnlockRequest.with {
      $0.key = Data(key.utf8)
    }
    return self.retryManager.execute { callOptions in
      return self.client.unlock(request, callOptions: callOptions).response
    }
  }
  
}
