//
//  File.swift
//  File
//
//  Created by Xiangyue Meng on 2021/9/3.
//

import Foundation
import NIO
import EtcdProto

typealias ElectionClient = V3electionpb_ElectionClient

public typealias CampaignRequest = V3electionpb_CampaignRequest
public typealias CampaignResponse = V3electionpb_CampaignResponse

public typealias ProclaimRequest = V3electionpb_ProclaimRequest
public typealias ProclaimResponse = V3electionpb_ProclaimResponse

public typealias LeaderRequest = V3electionpb_LeaderRequest
public typealias LeaderResponse = V3electionpb_LeaderResponse

public typealias ResignRequest = V3electionpb_ResignRequest
public typealias ResignResponse = V3electionpb_ResignResponse

public class Election {
  private let client: ElectionClient
  private let retryManager: RetryManager
  
  init(client: ElectionClient, retryManager: RetryManager) {
    self.client = client
    self.retryManager = retryManager
  }
  
  public func campaign(electionName: String, leaseId: Int64, proposal: String) -> EventLoopFuture<CampaignResponse> {
    let request = CampaignRequest.with {
      $0.name = Data(electionName.utf8)
      $0.value = Data(proposal.utf8)
      $0.lease = leaseId
    }
    // TODO: different with jetcd
    return self.retryManager.execute { callOptions in
      return self.client.campaign(request, callOptions: callOptions).response
    }
  }
}
