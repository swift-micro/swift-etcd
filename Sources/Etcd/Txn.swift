//
//  File.swift
//  File
//
//  Created by xiangyue on 2021/9/2.
//

import Foundation
import NIO

public protocol Txn {
  func `if`(cmps: Cmp...) throws -> Txn
  func then(ops: Op...) throws -> Txn
  func `else`(ops: Op...) -> Txn
  func commit() -> EventLoopFuture<TxnResponse>
}


class TxnImp: Txn {
  private var commitColsure: (TxnRequest) -> EventLoopFuture<TxnResponse>
  private var cmpList: [Cmp] = []
  private var successOpList: [Op] = []
  private var failureOpList: [Op] = []
  
  private var seenThen = false
  private var seenElse = false
  
  init(commitColsure: @escaping (TxnRequest) -> EventLoopFuture<TxnResponse>) {
    self.commitColsure = commitColsure
  }

  func `if`(cmps: Cmp...) throws -> Txn {
    guard seenThen == false else {
      throw EtcdError(code: .illegalArgument, message: "cannot call If after Then!")
    }
    guard seenElse == false else {
      throw EtcdError(code: .illegalArgument, message: "cannot call If after Else!")
    }
    self.cmpList.append(contentsOf: cmps)
    return self
  }
  
  func then(ops: Op...) throws -> Txn {
    guard seenElse == false else {
      throw EtcdError(code: .illegalArgument, message: "cannot call If after Else!")
    }
    self.seenThen = true
    self.successOpList.append(contentsOf: ops)
    return self
  }
  
  func `else`(ops: Op...) -> Txn {
    self.seenElse = true
    self.failureOpList.append(contentsOf: ops)
    return self
  }
  
  func commit() -> EventLoopFuture<TxnResponse> {
    let request = TxnRequest.with {
      $0.compare = cmpList.map { $0.toCompare() }
      $0.success = successOpList.map { $0.requestOp }
      $0.failure = failureOpList.map { $0.requestOp }
    }
    return commitColsure(request)
  }
}
