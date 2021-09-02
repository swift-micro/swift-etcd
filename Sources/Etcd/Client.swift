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

/// A threading lock based on `libpthread` instead of `libdispatch`.
///
/// This object provides a lock on top of a single `pthread_mutex_t`. This kind
/// of lock is safe to use with `libpthread`-based threading models, such as the
/// one used by NIO.
internal final class Lock {
    private let mutex: UnsafeMutablePointer<pthread_mutex_t> = UnsafeMutablePointer.allocate(capacity: 1)

    /// Create a new lock.
    public init() {
        let err = pthread_mutex_init(self.mutex, nil)
        precondition(err == 0)
    }

    deinit {
        let err = pthread_mutex_destroy(self.mutex)
        precondition(err == 0)
        self.mutex.deallocate()
    }

    /// Acquire the lock.
    ///
    /// Whenever possible, consider using `withLock` instead of this method and
    /// `unlock`, to simplify lock handling.
    public func lock() {
        let err = pthread_mutex_lock(self.mutex)
        precondition(err == 0)
    }

    /// Release the lock.
    ///
    /// Whenever possible, consider using `withLock` instead of this method and
    /// `lock`, to simplify lock handling.
    public func unlock() {
        let err = pthread_mutex_unlock(self.mutex)
        precondition(err == 0)
    }
}

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
  
  public init(clientConnetion: ClientConnection, etcdClientOptions: EtcdClient.Options) {
    self.clientConnetion = clientConnetion
    self.options = etcdClientOptions
    let authClient = Etcdserverpb_AuthClient(channel: clientConnetion)
    self.retryManager = RetryManager(authClient: authClient, user: options.auth?.user, password: options.auth?.password)
  }
}



