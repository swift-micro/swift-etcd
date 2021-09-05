//
//  File.swift
//  File
//
//  Created by xiangyue on 2021/9/2.
//

import Foundation
import XCTest
import NIO
import GRPC
@testable import Etcd


final class KVTests: XCTestCase {
  
  private var group: MultiThreadedEventLoopGroup!
  private var connection: ClientConnection!
  
  var etcdClient: EtcdClient!
  
  override func setUp() {
    super.setUp()
    group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)


    connection = ClientConnection.insecure(group: group)
      .withConnectionTimeout(minimum: TimeAmount.seconds(1))
      .connect(host: "localhost", port: 2379)
    
    let auth = EtcdClient.Options.Auth(user: "dev", password: "123")
    let options = EtcdClient.Options(auth: auth)
    etcdClient = EtcdClient(clientConnetion: connection, etcdClientOptions: options)
  }
  
  override func tearDown() {
    XCTAssertNoThrow(try self.connection.close().wait())
    XCTAssertNoThrow(try self.group.syncShutdownGracefully())
    super.tearDown()
  }
  
  
  func testGet() throws {
    let response = etcdClient.kv.get(key: "/dev/database")
    let value = try response.wait().kvs.first?.value
    XCTAssertNotNil(value)
    XCTAssertEqual(String(data: value!, encoding: .utf8), "xiangyue")
  }
  
  func testTxn() throws {
    let key = "/dev/database".data(using: .utf8)!
    let putRequest = PutRequest.with {
      $0.key = key
      $0.value = "new-xiangyue".data(using: .utf8)!
    }
    let elsePutRequest = PutRequest.with {
      $0.key = key
      $0.value = "new-xiangyue-else".data(using: .utf8)!
    }
    let txn = etcdClient.kv.txn()
    let response = try txn.if(cmps:
                  Cmp(key: key, operator: .equal, cmpTarget: CmpTarget.value("xiangyue".data(using: .utf8)!))
                )
                .then(ops: Op.put(putRequest))
                .else(ops: Op.put(elsePutRequest))
                .commit()
                .wait()
    XCTAssertEqual(response.succeeded, true)
  }
}
