import Foundation
import GRPC
import EtcdProto
import NIO
import NIOHPACK
import Etcd


let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

// Make sure the group is shutdown when we're done with it.
defer {
  try! group.syncShutdownGracefully()
}

// Configure the channel, we're not using TLS so the connection is `insecure`.
let channel = ClientConnection.insecure(group: group)
  .withConnectionTimeout(minimum: TimeAmount.seconds(1))
  .connect(host: "localhost", port: 2379)
  
  

// Close the connection when we're done with it.
defer {
  try! channel.close().wait()
}

print("================")


//let auth = Etcdserverpb_AuthClient(channel: channel)
//var authenticateRequest = Etcdserverpb_AuthenticateRequest.with {
//  $0.name = "dev"
//  $0.password = "123"
//}
//print("================1")
//let res = try auth.authenticate(authenticateRequest, callOptions: nil).response.wait()
//print("================2 ")
//print(res)
//
//let token = res.token
//let callOptions = CallOptions(customMetadata: HPACKHeaders([("token", "token")]))

// Provide the connection to the generated client.
//let greeter = Helloworld_GreeterClient(channel: channel)
//let kv = Etcdserverpb_KVClient(channel: channel)

//let newKv = KV(client: kv)
//newKv.token = token
//
//let response = try newKv.put(key: "/dev/name", value: "xiangyue").wait()
//print("1234554=\(response)")

//let request = Etcdserverpb_PutRequest.with {
//    $0.key = "/dev/name".data(using: .utf8)!
//    $0.value = "xiangyue".data(using: .utf8)!
//}
//
//
//do {
//  let response = try kv.put(request, callOptions: callOptions).response.wait()
//  print("res = \(response)")
//} catch let error where error is GRPCStatus {
//  if (error as! GRPCStatus).code == .unauthenticated {
//    print("retry")
//  }
//  print(error)
//}



//let rangeReq = Etcdserverpb_RangeRequest.with {
//    $0.key = "name".data(using: .utf8)!
//}
//
//let rangeRes = try kv.range(rangeReq, callOptions: callOptions).response.wait()
//print("res = \(rangeRes)")



let auth = EtcdClient.Options.Auth(user: "dev", password: "123")
let options = EtcdClient.Options(auth: auth)
var etcdClient: EtcdClient? = EtcdClient(clientConnetion: channel, etcdClientOptions: options)
print("mxy----前 \(CFGetRetainCount( etcdClient!.kv))")
let responseFuture = try etcdClient!.kv.put(key: "/dev/new", value: "new test")
//etcdClient = nil

let response = try responseFuture.wait()
//print("mxy----后 \(CFGetRetainCount( etcdClient!.kv))")
//print(response)
//let eventloop1 = try etcdClient.kv.put(key: "/dev/new", value: "new test").eventLoop
//print("1111111\(eventloop1)")
//let eventloop2 = eventloop1.scheduleTask(in: TimeAmount.seconds(1)) {
//  print("22332323")
//}.futureResult.eventLoop
//print("1111111\(eventloop2)")
//
//let eventloop3 = try etcdClient.kv.put(key: "/dev/new", value: "new test").eventLoop
//print("11111112\(eventloop3)")
//let eventloop4 = eventloop1.scheduleTask(in: TimeAmount.seconds(1)) {
//  print("223323234")
//}.futureResult.eventLoop
//print("11111112\(eventloop4)")
//
//try etcdClient.kv.put(key: "/dev/new", value: "new test").eventLoop.scheduleTask(in: TimeAmount.seconds(1), {
//  print("ffffff")
//}).futureResult.wait()


let dispatchGroup = DispatchGroup()
dispatchGroup.enter()
dispatchGroup.wait()
