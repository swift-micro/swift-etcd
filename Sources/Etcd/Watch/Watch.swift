//
//  File.swift
//  File
//
//  Created by Xiangyue Meng on 2021/9/3.
//

import Foundation
import EtcdProto
import NIO
import GRPC


typealias WatchClient = Etcdserverpb_WatchClient

public typealias WatchRequest = Etcdserverpb_WatchRequest
public typealias WatchResponse = Etcdserverpb_WatchResponse

public typealias WatchCreateRequest = Etcdserverpb_WatchCreateRequest
public typealias WatchCancelRequest = Etcdserverpb_WatchCancelRequest
public typealias WatchProgressRequest = Etcdserverpb_WatchProgressRequest

public protocol WatchListener {
  func onNext(response: WatchResponse)
  func onError(_ error: EtcdError)
  func onCompleted()
}

public class Watch {
  private let client: WatchClient
  private let retryManager: RetryManager
  
  private var watchers: [Watcher] = []
  
  init(client: WatchClient, retryManager: RetryManager) {
    self.client = client
    self.retryManager = retryManager
  }
  
  public func watch(request: WatchCreateRequest, listener: WatchListener) -> Watcher {
    let r = WatchRequest.with {
      $0.createRequest = request
    }
    let watcher = Watcher(client: self.client, request: r, listener: listener, retryManager: retryManager) { [weak self] uuid in
      // TODO: remove watcher with lock
      self?.watchers.removeAll { $0.uuid == uuid }
    }
    self.watchers.append(watcher)
    return watcher
  }
  
  public func close() {
    
  }
}

extension WatchResponse {
  var isProgressNotify: Bool {
    return events.count == 0
      && created == false
      && canceled == false
      && compactRevision == 0
    && header.revision != 0
  }
}
