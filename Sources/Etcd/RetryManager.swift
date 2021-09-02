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
  
  init(authClient: Etcdserverpb_AuthClient, user: String? = nil, password: String? = nil) {
    self.authClient = authClient
    self.user = user
    self.password = password
  }
  
  var retryCount = 0
  func execute<T>(callOptions: CallOptions = CallOptions(), task: @escaping (CallOptions) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
    var newCallOptions = callOptions
    newCallOptions.customMetadata.replaceOrAdd(name: "token", value: token ?? "")
    let responseFuture = task(newCallOptions)
    let eventloop = responseFuture.eventLoop
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
              let refreshTokenFutrue: EventLoopFuture<T> = strongSelf.generateToken(eventloop: eventloop, user: user, password: password).flatMap { token in
                strongSelf.token = token
                newCallOptions.customMetadata.replaceOrAdd(name: "token", value: token)
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
  
  private func generateToken(eventloop: EventLoop, user: String, password: String) -> EventLoopFuture<String> {
    let request = Etcdserverpb_AuthenticateRequest.with {
      $0.name = user
      $0.password = password
    }
    return authClient.authenticate(request, callOptions: nil).response.map { response in
      return response.token
    }
  }
}
