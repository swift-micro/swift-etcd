// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-etcd",
    products: [
      .library(name: "Etcd", targets: ["Etcd"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "swift-etcd",
            dependencies: [
                .target(name: "EtcdProto"),
                .target(name: "Etcd")
            ]),
        .testTarget(
            name: "swift-etcdTests",
            dependencies: ["swift-etcd"]),
        .target(
            name: "EtcdProto",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "GRPC", package: "grpc-swift"),
            ],
            exclude: ["auth.proto", "election.proto", "kv.proto", "lock.proto", "rpc.proto"]
        ),
        .target(
            name: "Etcd",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "GRPC", package: "grpc-swift"),
                .target(name: "EtcdProto")
            ]
          ),
        .testTarget(
            name: "EtcdTest",
            dependencies: [
              .product(name: "Logging", package: "swift-log"),
              .product(name: "GRPC", package: "grpc-swift"),
              .target(name: "EtcdProto"),
              .target(name: "Etcd"),
            ]
          )
    ]
)
