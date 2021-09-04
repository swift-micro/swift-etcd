//
//  File.swift
//  File
//
//  Created by xiangyue on 2021/8/26.
//

import Foundation
import GRPC
import EtcdProto
import NIOConcurrencyHelpers

typealias KVClient = Etcdserverpb_KVClient
typealias AuthClient = Etcdserverpb_AuthClient


// hard to resolve retain cycle problem
final class MemoizingClientSupplier<T> {
  private let delegate: () -> T
  private let lock = Lock()
  private var value: T?
  
  init(delegate: @escaping () -> T) {
    self.delegate = delegate
  }
  
  func get() -> T {
    if let value = value {
      return value
    }
    lock.lock()
    defer {
      lock.unlock()
    }
    let t = delegate()
    value = t
    return t
  }
}

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
  
  // MARK: - KV Property
  private var _kv: KV?
  private let _kvLock = Lock()
  public var kv: KV {
    if let _kv = _kv {
      return _kv
    }
    _kvLock.lock()
    defer { _kvLock.unlock() }
    let kvClient = KVClient(channel: clientConnetion)
    let newKv = KV(client: kvClient, retryManager: retryManager)
    _kv = newKv
    return newKv
  }
  
  // MARK: - Auth Property
  private var _auth: Auth?
  private let _authLock = Lock()
  public var auth: Auth {
    if let _auth = _auth {
      return _auth
    }
    _authLock.lock()
    defer { _authLock.unlock() }
    let authClient = AuthClient(channel: clientConnetion)
    let newAuth = Auth(client: authClient, retryManager: retryManager)
    _auth = newAuth
    return newAuth
  }
  
  
  // MARK: - Init
  public init(clientConnetion: ClientConnection, etcdClientOptions: EtcdClient.Options) {
    self.clientConnetion = clientConnetion
    self.options = etcdClientOptions
    let authClient = Etcdserverpb_AuthClient(channel: clientConnetion)
    self.retryManager = RetryManager(authClient: authClient, user: options.auth?.user, password: options.auth?.password)
  }
}



