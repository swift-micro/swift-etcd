//
//  File.swift
//  File
//
//  Created by xiangyue on 2021/9/2.
//

import Foundation
import EtcdProto
import NIO
import CoreMedia

public typealias AuthEnableRequest = Etcdserverpb_AuthEnableRequest
public typealias AuthEnableResponse = Etcdserverpb_AuthEnableResponse

public typealias AuthDisableRequest = Etcdserverpb_AuthDisableRequest
public typealias AuthDisableResponse = Etcdserverpb_AuthDisableResponse

public typealias AuthUserAddRequest = Etcdserverpb_AuthUserAddRequest
public typealias AuthUserAddResponse = Etcdserverpb_AuthUserAddResponse

public typealias AuthUserDeleteRequest = Etcdserverpb_AuthUserDeleteRequest
public typealias AuthUserDeleteResponse = Etcdserverpb_AuthUserDeleteResponse

public typealias AuthUserChangePasswordRequest = Etcdserverpb_AuthUserChangePasswordRequest
public typealias AuthUserChangePasswordResponse = Etcdserverpb_AuthUserChangePasswordResponse

public typealias AuthUserGetRequest = Etcdserverpb_AuthUserGetRequest
public typealias AuthUserGetResponse = Etcdserverpb_AuthUserGetResponse

public typealias AuthUserListRequest = Etcdserverpb_AuthUserListRequest
public typealias AuthUserListResponse = Etcdserverpb_AuthUserListResponse

public typealias AuthUserGrantRoleRequest = Etcdserverpb_AuthUserGrantRoleRequest
public typealias AuthUserGrantRoleResponse = Etcdserverpb_AuthUserGrantRoleResponse

public typealias AuthUserRevokeRoleRequest = Etcdserverpb_AuthUserRevokeRoleRequest
public typealias AuthUserRevokeRoleResponse = Etcdserverpb_AuthUserRevokeRoleResponse

public typealias AuthRoleAddRequest = Etcdserverpb_AuthRoleAddRequest
public typealias AuthRoleAddResponse = Etcdserverpb_AuthRoleAddResponse

public typealias AuthRoleGrantPermissionRequest = Etcdserverpb_AuthRoleGrantPermissionRequest
public typealias AuthRoleGrantPermissionResponse = Etcdserverpb_AuthRoleGrantPermissionResponse

public typealias AuthRoleGetRequest = Etcdserverpb_AuthRoleGetRequest
public typealias AuthRoleGetResponse = Etcdserverpb_AuthRoleGetResponse

public typealias AuthRoleListRequest = Etcdserverpb_AuthRoleListRequest
public typealias AuthRoleListResponse = Etcdserverpb_AuthRoleListResponse

public typealias AuthRoleRevokePermissionRequest = Etcdserverpb_AuthRoleRevokePermissionRequest
public typealias AuthRoleRevokePermissionResponse = Etcdserverpb_AuthRoleRevokePermissionResponse

public typealias AuthRoleDeleteRequest = Etcdserverpb_AuthRoleDeleteRequest
public typealias AuthRoleDeleteResponse = Etcdserverpb_AuthRoleDeleteResponse

public typealias AuthPermissionType = Authpb_Permission.TypeEnum

public class Auth {
  private let client: AuthClient
  private let retryManager: RetryManager
  
  init(client: Etcdserverpb_AuthClient, retryManager: RetryManager) {
    self.client = client
    self.retryManager = retryManager
  }
  
  public func authEnable() -> EventLoopFuture<AuthEnableResponse> {
    let request = AuthEnableRequest()
    return self.retryManager.execute { callOptions in
      self.client.authEnable(request, callOptions: callOptions).response
    }
  }
  
  public func authDisable() -> EventLoopFuture<AuthDisableResponse> {
    let request = AuthDisableRequest()
    return self.retryManager.execute { callOptions in
      self.client.authDisable(request, callOptions: callOptions).response
    }
  }
  
  public func userAdd(name: String, password: String) -> EventLoopFuture<AuthUserAddResponse> {
    let request = AuthUserAddRequest.with {
      $0.name = name
      $0.password = password
    }
    return self.retryManager.execute { callOptions in
      return self.client.userAdd(request, callOptions: callOptions).response
    }
  }
  
  public func userDelete(name: String) -> EventLoopFuture<AuthUserDeleteResponse> {
    let request = AuthUserDeleteRequest.with {
      $0.name = name
    }
    return self.retryManager.execute { callOptions in
      return self.client.userDelete(request, callOptions: callOptions).response
    }
  }
  
  public func userChangePassword(name: String, password: String) -> EventLoopFuture<AuthUserChangePasswordResponse> {
    let request = AuthUserChangePasswordRequest.with {
      $0.name = name
      $0.password = password
    }
    return self.retryManager.execute { callOptions in
      self.client.userChangePassword(request, callOptions: callOptions).response
    }
  }
  
  public func userGet(name: String) -> EventLoopFuture<AuthUserGetResponse> {
    let request = AuthUserGetRequest.with {
      $0.name = name
    }
    return self.retryManager.execute { callOptions in
      return self.client.userGet(request, callOptions: callOptions).response
    }
  }
  
  public func userList() -> EventLoopFuture<AuthUserListResponse> {
    let request = AuthUserListRequest()
    return self.retryManager.execute { callOptions in
      return self.client.userList(request, callOptions: callOptions).response
    }
  }
  
  public func userGrantRole(name: String, role: String) -> EventLoopFuture<AuthUserGrantRoleResponse> {
    let request = AuthUserGrantRoleRequest.with {
      $0.user = name
      $0.role = role
    }
    return self.retryManager.execute { callOptions in
      return self.client.userGrantRole(request, callOptions: callOptions).response
    }
  }
  
  public func userRevokeRole(name: String, role: String) -> EventLoopFuture<AuthUserRevokeRoleResponse> {
    let request = AuthUserRevokeRoleRequest.with {
      $0.name = name
      $0.role = role
    }
    return self.retryManager.execute { callOptions in
      return self.client.userRevokeRole(request, callOptions: callOptions).response
    }
  }
  
  public func roleAdd(role: String) -> EventLoopFuture<AuthRoleAddResponse> {
    let request = AuthRoleAddRequest.with {
      $0.name = role
    }
    return self.retryManager.execute { callOptions in
      return self.client.roleAdd(request, callOptions: callOptions).response
    }
  }
  
  public func roleGrantPermission(role: String, key: String, rangeEnd: String, permissionType: AuthPermissionType) -> EventLoopFuture<Etcdserverpb_AuthRoleGrantPermissionResponse> {
    let permission = Authpb_Permission.with {
      $0.key = Data(key.utf8)
      $0.rangeEnd = Data(rangeEnd.utf8)
      $0.permType = permissionType
    }
    let request = AuthRoleGrantPermissionRequest.with {
      $0.name = role
      $0.perm = permission
    }
    return self.retryManager.execute { callOptions in
      return self.client.roleGrantPermission(request, callOptions: callOptions).response
    }
  }
  
  public func roleGet(role: String) -> EventLoopFuture<AuthRoleGetResponse> {
    let request = AuthRoleGetRequest.with {
      $0.role = role
    }
    return self.retryManager.execute { callOptions in
      return self.client.roleGet(request, callOptions: callOptions).response
    }
  }
  
  public func roleList() -> EventLoopFuture<AuthRoleListResponse> {
    let request = AuthRoleListRequest()
    return self.retryManager.execute { callOptions in
      return self.client.roleList(request, callOptions: callOptions).response
    }
  }
  
  public func roleRevokePermission(role: String, key: String, rangeEnd: String) -> EventLoopFuture<AuthRoleRevokePermissionResponse> {
    let request = AuthRoleRevokePermissionRequest.with {
      $0.role = role
      $0.key = key
      $0.rangeEnd = rangeEnd
    }
    return self.retryManager.execute { callOptions in
      return self.client.roleRevokePermission(request, callOptions: callOptions).response
    }
  }
  
  public func roleDelete(role: String) -> EventLoopFuture<AuthRoleDeleteResponse> {
    let request = AuthRoleDeleteRequest.with {
      $0.role = role
    }
    return self.retryManager.execute { callOptions in
      return self.client.roleDelete(request, callOptions: callOptions).response
    }
  }
}
