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
public class KV {
  // mxy remove
  public var token: String = ""
  private let client: Etcdserverpb_KVClient
  private let retryManager: RetryManager
  // remove public 
  init(client: Etcdserverpb_KVClient, retryManager: RetryManager) {
    self.client = client
    self.retryManager = retryManager
  }
  public func put(key: String, value: String) throws -> EventLoopFuture<Etcdserverpb_PutResponse> {
    guard let keyData = key.data(using: .utf8), let valueData = value.data(using: .utf8) else {
      throw EtcdError.dataFormatIsWrong
    }
    let request = PutRequest.with {
      $0.key = keyData
      $0.value = valueData
    }
    return put(request: request)
  }
  
  public func put(request: PutRequest) -> EventLoopFuture<Etcdserverpb_PutResponse> {
    let callOptions = CallOptions(customMetadata: HPACKHeaders([("token", "token")]))
    return retryManager.execute(callOptions: callOptions) { callOptions in
      print("client.put(request, callOptions: callOptions).response")
      return self.client.put(request, callOptions: callOptions).response
    }
//    return try execute(callOptions: callOptions) { callOptions in
//      print("client.put(request, callOptions: callOptions).response")
//      return self.client.put(request, callOptions: callOptions).response
//    }
  }
  
  // ========================================================NOT USED =========================================
  func refreshToken() throws -> EventLoopFuture<String> {
    let request = Etcdserverpb_PutRequest.with {
        $0.key = "/dev/name".data(using: .utf8)!
        $0.value = "xiangyue".data(using: .utf8)!
    }
    let callOptions = CallOptions(customMetadata: HPACKHeaders([("token", token)]))
    return self.client.put(request, callOptions: callOptions).response.map { _ in
      print("==========Auth token result ===========")
      return self.token
    }
//    return try self.put(key: "/dev/auth", value: "auth test")
  }
  
  var retryCount = 0
  func execute<T>(callOptions: CallOptions, task: @escaping (CallOptions) -> EventLoopFuture<T>) throws -> EventLoopFuture<T> {
    let responseFuture = task(callOptions)
    
    let eventloop = responseFuture.eventLoop
    
    let promise = responseFuture.eventLoop.makePromise(of: T.self)
    responseFuture.whenComplete { result in
      switch result {
      case .success(let response):
        promise.succeed(response)
      case .failure(let error):
        if let error = error as? GRPCStatus, error.code == .unauthenticated {
          print("erroro===")
          self.retryCount += 1
          if self.retryCount % 3 != 0 {
//            let callOptions = CallOptions(customMetadata: HPACKHeaders([("token", self.token)]))
//            promise.completeWith(task(callOptions))
            
            do {
              let refrsheTokenFuture: EventLoopFuture<T>  = try self.refreshToken().flatMap { (token: String) in
                let callOptions = CallOptions(customMetadata: HPACKHeaders([("token", token)]))
                return task(callOptions)
              }
              promise.completeWith(refrsheTokenFuture)
            } catch {
              print("new error ==========")
            }
            return
          }
        }
        promise.fail(error)
      }
    }
    return promise.futureResult
  }
}



