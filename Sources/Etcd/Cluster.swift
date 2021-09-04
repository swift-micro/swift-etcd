//
//  File.swift
//  File
//
//  Created by Xiangyue Meng on 2021/9/3.
//

import Foundation
import NIO
import EtcdProto

typealias ClusterClient = Etcdserverpb_ClusterClient

public typealias MemberListRequest = Etcdserverpb_MemberListRequest
public typealias MemberListResponse = Etcdserverpb_MemberListResponse

public typealias MemberAddRequest = Etcdserverpb_MemberAddRequest
public typealias MemberAddResponse = Etcdserverpb_MemberAddResponse

public typealias MemberRemoveRequest = Etcdserverpb_MemberRemoveRequest
public typealias MemberRemoveResponse = Etcdserverpb_MemberRemoveResponse

public typealias MemberUpdateRequest = Etcdserverpb_MemberUpdateRequest
public typealias MemberUpdateResponse = Etcdserverpb_MemberUpdateResponse

public class Cluster {
  private let client: ClusterClient
  private let retryManager: RetryManager
  
  init(client: ClusterClient, retryManager: RetryManager) {
    self.client = client
    self.retryManager = retryManager
  }
  
  public func listMember() -> EventLoopFuture<MemberListResponse> {
    let request = MemberListRequest()
    return self.retryManager.execute { callOptions in
      return self.client.memberList(request, callOptions: callOptions).response
    }
  }
  
  public func addMember(peerUrls: [String]) -> EventLoopFuture<MemberAddResponse> {
    let request = MemberAddRequest.with {
      $0.peerUrls = peerUrls
    }
    return self.retryManager.execute { callOptions in
      return self.client.memberAdd(request, callOptions: callOptions).response
    }
  }
  
  public func removeMember(id: UInt64) -> EventLoopFuture<MemberRemoveResponse> {
    let request = MemberRemoveRequest.with {
      $0.id = id
    }
    return self.retryManager.execute { callOptions in
      return self.client.memberRemove(request, callOptions: callOptions).response
    }
  }
  
  // TODO: check change [String] to [URL]
  public func updateMember(id: UInt64, peerUrls: [String]) -> EventLoopFuture<MemberUpdateResponse> {
    let request = MemberUpdateRequest.with {
      $0.id = id
      $0.peerUrls = peerUrls
    }
    return self.retryManager.execute { callOptions in
      return self.client.memberUpdate(request, callOptions: callOptions).response
    }
  }
}

