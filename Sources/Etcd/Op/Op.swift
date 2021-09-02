//
//  File.swift
//  File
//
//  Created by xiangyue on 2021/9/2.
//

import Foundation
import EtcdProto

typealias RequestOp = Etcdserverpb_RequestOp

public enum Op {
  case range(RangeRequest)
  case put(PutRequest)
  case delete(DeleteRangeRequest)
  case txn(TxnRequest)
  
  var requestOp: RequestOp {
    var request: Etcdserverpb_RequestOp.OneOf_Request? = nil
    switch self {
    case .range(let rangeRequest):
      request = .requestRange(rangeRequest)
    case .put(let putRequest):
      request = .requestPut(putRequest)
    case .delete(let deleteRangeRequest):
      request = .requestDeleteRange(deleteRangeRequest)
    case .txn(let txnRequest):
      request = .requestTxn(txnRequest)
    }
    
    var op = RequestOp()
    op.request = request
    return op
  }
}
