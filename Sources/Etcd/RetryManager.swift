//
//  File.swift
//  File
//
//  Created by xiangyue on 2021/8/26.
//

import Foundation
import NIO
import NIOHPACK
import GRPC
import EtcdProto

class RetryManager {
  private let authClient: Etcdserverpb_AuthClient
  private let user: String?
  private let password: String?
  private var token: String?
  
  private(set) var callOptions: CallOptions
  
  init(authClient: Etcdserverpb_AuthClient, user: String? = nil, password: String? = nil) {
    self.authClient = authClient
    self.user = user
    self.password = password
    self.callOptions = CallOptions()
  }
  
  var retryCount = 0
  func execute<T>(task: @escaping (_ callOptions: CallOptions) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
    return self.execute(callOptions: self.callOptions, task: task)
  }
  
  func execute<T>(callOptions: CallOptions, task: @escaping (_ callOptions: CallOptions) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
    var newCallOptions = callOptions
    newCallOptions.customMetadata.replaceOrAdd(name: "token", value: token ?? "")
    self.callOptions = newCallOptions
    let responseFuture = task(newCallOptions)
    let promise = responseFuture.eventLoop.makePromise(of: T.self)
    responseFuture.whenComplete { [weak self] result in
      switch result {
      case .success(let response):
        promise.succeed(response)
      case .failure(let error):
        guard let strongSelf = self, strongSelf.retryCount < 3 else {
          promise.fail(error)
          return
        }
        if let error = error as? GRPCStatus {
          if error.code == .unauthenticated {
            if let user = strongSelf.user, let password = strongSelf.password {
              let refreshTokenFutrue: EventLoopFuture<T> = strongSelf.generateToken(user: user, password: password).flatMap { token in
                strongSelf.token = token
                newCallOptions.customMetadata.replaceOrAdd(name: "token", value: token)
                self?.callOptions = newCallOptions
                return task(newCallOptions)
              }
              promise.completeWith(refreshTokenFutrue)
              return
            }
          } else if error.code == .unavailable {
            promise.completeWith(task(callOptions))
            return
          }
        }
        promise.fail(error)
      }
    }
    return promise.futureResult
  }
  
  func generateToken() -> EventLoopFuture<String>? {
    guard let _user = self.user, let _passwrod = self.password else {
      return nil
    }
    return generateToken(user: _user, password: _passwrod)
  }
  
  func generateToken(user: String, password: String) -> EventLoopFuture<String> {
    let request = Etcdserverpb_AuthenticateRequest.with {
      $0.name = user
      $0.password = password
    }
    return authClient.authenticate(request, callOptions: nil).response.map { [weak self] response in
      self?.callOptions.customMetadata.replaceOrAdd(name: "token", value: response.token)
      return response.token
    }
  }
}
