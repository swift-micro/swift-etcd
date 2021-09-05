//
//  File.swift
//  File
//
//  Created by xiangyue on 2021/9/5.
//

import Foundation
import GRPC
import EtcdProto
import NIO

private var leaseStreamingcall: BidirectionalStreamingCall<Etcdserverpb_LeaseKeepAliveRequest, Etcdserverpb_LeaseKeepAliveResponse>!

func testLease(clientConnection: ClientConnection, token: String ) throws {
  let client = Etcdserverpb_LeaseClient(channel: clientConnection)
  let id: Int64 = 10001
  
  let leaseLiveRequest = Etcdserverpb_LeaseTimeToLiveRequest.with {
    $0.id = id
  }
  
  let leaseResponse = try client.leaseTimeToLive(leaseLiveRequest, callOptions: nil).response.wait()
  print(leaseResponse)
  
  if leaseResponse.ttl != -1 {
    let revokeRequest = Etcdserverpb_LeaseRevokeRequest.with {
      $0.id = id
    }
    try client.leaseRevoke(revokeRequest, callOptions: nil).response.wait()
  }
  
  let r1 = Etcdserverpb_LeaseGrantRequest.with {
    $0.id = id
    $0.ttl = 1000000
  }
  let res = try client.leaseGrant(r1, callOptions: nil).response.wait()
  
  print(res)
  let request = Etcdserverpb_LeaseKeepAliveRequest.with {
    $0.id = id
  }
  leaseStreamingcall = client.leaseKeepAlive(callOptions: nil, handler: { response in
    print(response)
  })
  leaseStreamingcall.sendMessage(request)
}
