//
//  File.swift
//  File
//
//  Created by xiangyue on 2021/9/4.
//

import Foundation
import GRPC
import EtcdProto

var call: BidirectionalStreamingCall<Etcdserverpb_WatchRequest, Etcdserverpb_WatchResponse>!

func testWatch(clientConnection: ClientConnection, token: String ) {
  let client = Etcdserverpb_WatchClient(channel: clientConnection)
  resume(client: client, token: token, callOptions: CallOptions())
}

func resume(client: Etcdserverpb_WatchClient, token: String, callOptions: CallOptions) {
  
  let call = client.watch(callOptions: callOptions) { response in
    print(response)
    if response.cancelReason.contains("etcdserver: permission denied") {
      print("recreate with token")
      var newCallOptions = callOptions
      newCallOptions.customMetadata.replaceOrAdd(name: "token", value: token)
      resume(client: client, token: token, callOptions: newCallOptions)
    }
    
  }
  let createRequest = Etcdserverpb_WatchCreateRequest.with {
    $0.key = Data("/dev/database".utf8)
  }
  let request = Etcdserverpb_WatchRequest.with {
    $0.createRequest = createRequest
  }
  call.sendMessage(request, promise: nil)
}
