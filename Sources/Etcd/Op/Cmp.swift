//
//  File.swift
//  File
//
//  Created by xiangyue on 2021/9/2.
//

import Foundation
import EtcdProto

public typealias Compare = Etcdserverpb_Compare

public struct Cmp {
  
  public enum Operator {
    case equal
    case greater
    case less
    case notEqual
  }
  
  let key: Data
  let `operator`: Operator
  let cmpTarget: CmpTarget
  
  public init(key: Data, `operator` op: Operator, cmpTarget: CmpTarget) {
    self.key = key
    self.operator = op
    self.cmpTarget = cmpTarget
  }
  
  func toCompare() -> Compare {
    return Compare.with {
      $0.key = key
      switch `operator` {
      case .equal:
        $0.result = .equal
      case .greater:
        $0.result = .greater
      case .less:
        $0.result = .less
      case .notEqual:
        $0.result = .notEqual
      }
      
      let compareTarget = cmpTarget.target
      $0.target = compareTarget
      $0.targetUnion = cmpTarget.targetUnion
    }
  }
}



