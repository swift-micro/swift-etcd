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

public class EtcdClient {
  // TODO: update options
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
  
  
//  // MARK: - KV Property
//  private var _kv: KV?
//  private let _kvLock = Lock()
//  public var kv: KV {
//    if let _kv = _kv {
//      return _kv
//    }
//    _kvLock.lock()
//    defer { _kvLock.unlock() }
//    let kvClient = KVClient(channel: clientConnetion)
//    let newKv = KV(client: kvClient, retryManager: retryManager)
//    _kv = newKv
//    return newKv
//  }
//
//  // MARK: - Auth Property
//  private var _auth: Auth?
//  private let _authLock = Lock()
//  public var auth: Auth {
//    if let _auth = _auth {
//      return _auth
//    }
//    _authLock.lock()
//    defer { _authLock.unlock() }
//    let authClient = AuthClient(channel: clientConnetion)
//    let newAuth = Auth(client: authClient, retryManager: retryManager)
//    _auth = newAuth
//    return newAuth
//  }
  
  private lazy var authClietSupplier: MemoizingClientSupplier<Auth> = MemoizingClientSupplier(parent: self) { parent in
    let client = AuthClient(channel: parent.clientConnetion)
    return Auth(client: client, retryManager: parent.retryManager)
  }
  public var auth: Auth {
    return authClietSupplier.get()
  }
  
  private lazy var kvClietSupplier: MemoizingClientSupplier<KV> = MemoizingClientSupplier(parent: self) { parent in
    let client = KVClient(channel: parent.clientConnetion)
    return KV(client: client, retryManager: parent.retryManager)
  }
  public var kv: KV {
    return kvClietSupplier.get()
  }
  
  private lazy var clusterClietSupplier: MemoizingClientSupplier<Cluster> = MemoizingClientSupplier(parent: self) { parent in
    let client = ClusterClient(channel: parent.clientConnetion)
    return Cluster(client: client, retryManager: parent.retryManager)
  }
  public var cluster: Cluster {
    return clusterClietSupplier.get()
  }
  
  private lazy var maintenanceClietSupplier: MemoizingClientSupplier<Maintenance> = MemoizingClientSupplier(parent: self) { parent in
    let client = MaintenanceClient(channel: parent.clientConnetion)
    return Maintenance(client: client, retryManager: parent.retryManager, eventLoop: parent.clientConnetion.eventLoop)
  }
  public var maintenance: Maintenance {
    return maintenanceClietSupplier.get()
  }
  
  private lazy var leaseClietSupplier: MemoizingClientSupplier<Lease> = MemoizingClientSupplier(parent: self) { parent in
    let client = LeaseClient(channel: parent.clientConnetion)
    return Lease(client: client, retryManager: parent.retryManager, eventLoop: parent.clientConnetion.eventLoop)
  }
  public var lease: Lease {
    return leaseClietSupplier.get()
  }
  
  private lazy var watchClietSupplier: MemoizingClientSupplier<Watch> = MemoizingClientSupplier(parent: self) { parent in
    let client = WatchClient(channel: parent.clientConnetion)
    return Watch(client: client, retryManager: parent.retryManager)
  }
  public var watch: Watch {
    return watchClietSupplier.get()
  }
  
  private lazy var lockClietSupplier: MemoizingClientSupplier<EtcdLock> = MemoizingClientSupplier(parent: self) { parent in
    let client = LockClient(channel: parent.clientConnetion)
    return EtcdLock(client: client, retryManager: parent.retryManager)
  }
  public var lock: EtcdLock {
    return lockClietSupplier.get()
  }
  
  private lazy var electionClietSupplier: MemoizingClientSupplier<Election> = MemoizingClientSupplier(parent: self) { parent in
    let client = ElectionClient(channel: parent.clientConnetion)
    return Election(client: client, retryManager: parent.retryManager)
  }
  public var election: Election {
    return electionClietSupplier.get()
  }
  
  // MARK: - Init
  public init(clientConnetion: ClientConnection, etcdClientOptions: EtcdClient.Options) {
    self.clientConnetion = clientConnetion
    self.options = etcdClientOptions
    let authClient = Etcdserverpb_AuthClient(channel: clientConnetion)
    self.retryManager = RetryManager(authClient: authClient, user: options.auth?.user, password: options.auth?.password)
  }
}


// hard to resolve retain cycle problem
final private class MemoizingClientSupplier<T> {
  unowned let parent: EtcdClient
  private let delegate: (EtcdClient) -> T
  private var value: T?
  
  private let lock = Lock()

  init(parent: EtcdClient, delegate: @escaping (_ parent: EtcdClient) -> T) {
    self.parent = parent
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
    let t = delegate(self.parent)
    value = t
    return t
  }
}
