//
//  File.swift
//  File
//
//  Created by xiangyue on 2021/8/26.
//

import Foundation

public enum EtcdError: Error {
  case dataFormatIsWrong
  case illegalArgument(String?)
}