//
//  File.swift
//  File
//
//  Created by xiangyue on 2021/8/26.
//

import Foundation
import GRPC
import EtcdProto

typealias KVClient = Etcdserverpb_KVClient

public class EtcdClient {
  public struct Options {
    public struct Auth {
      public var user: String
      public var password: String
      public init(user: String, password: String) {
        self.user = user
        self.password = password
      }
    }
    public var auth: Auth?
    
    public init(auth: Auth? = nil) {
      self.auth = auth
    }
  }
  private let clientConnetion: ClientConnection
  private let options: Options
  private let retryManager: RetryManager
  
  public var kv: KV
  public init(clientConnetion: ClientConnection, etcdClientOptions: EtcdClient.Options) {
    self.clientConnetion = clientConnetion
    self.options = etcdClientOptions
    let authClient = Etcdserverpb_AuthClient(channel: clientConnetion)
    self.retryManager = RetryManager(authClient: authClient, user: options.auth?.user, password: options.auth?.password)
    
    let kvClient = KVClient(channel: clientConnetion)
    self.kv = KV(client: kvClient, retryManager: retryManager)
  }
}



