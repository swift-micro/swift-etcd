//
//  File.swift
//  File
//
//  Created by xiangyue on 2021/9/2.
//

import Foundation
import EtcdProto



public enum CmpTarget {
  case version(Int64)
  case create(Int64)
  case mod(Int64)
  case value(Data)
  
  public var target: Compare.CompareTarget {
    switch self {
    case .version:
      return .version
    case .create:
      return .create
    case .mod:
      return .mod
    case .value:
      return .value
    }
  }
  
  var targetUnion: Etcdserverpb_Compare.OneOf_TargetUnion {
    switch self {
    case .version(let value):
      return .version(value)
    case .create(let value):
      return .createRevision(value)
    case .mod(let value):
      return .modRevision(value)
    case .value(let data):
      return .value(data)
    }
  }
}

