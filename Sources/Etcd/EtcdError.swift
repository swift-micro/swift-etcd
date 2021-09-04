//
//  File.swift
//  File
//
//  Created by xiangyue on 2021/8/26.
//

import Foundation
import GRPC

// ErrorCode is a wrapper around grpc Error code.
public enum ErrorCode: Int {
//  a wrapper around grpc Error code GRPCStatus.Code from 1 to 16
  case cancelled = 1
  case unknown = 2
  case invalidArgument = 3
  case deadlineExceeded = 4
  case notFound = 5
  case alreadyExists = 6
  case permissionDenied = 7
  case resourceExhausted = 8
  case failedPrecondition = 9
  case aborted = 10
  case outOfRange = 11
  case unimplemented = 12
  case internalError = 13
  case unavailable = 14
  case dataLoss = 15
  case unauthenticated = 16
  
  // custome
  case illegalArgument = 17
  case noAuthInfo = 18
  case cantHandle = 999
}

public struct EtcdError: Error {
  public var message: String?
  public var code: ErrorCode
  init(code: ErrorCode, message: String? = nil) {
    self.code = code
    self.message = message
  }
  
  static func from(grpcStatus status: GRPCStatus) -> EtcdError {
    if let code = ErrorCode(rawValue: status.code.rawValue) {
      return EtcdError(code: code, message: status.message)
    }
    return EtcdError(code: .cantHandle, message: "We don't know the error info")
  }
}
