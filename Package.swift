// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-etcd",
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "swift-etcd",
            dependencies: [
//                .product(name: "GRPC", package: "grpc-swift")
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
            ]
        ),
        .target(
            name: "Etcd",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "GRPC", package: "grpc-swift"),
                .target(name: "EtcdProto")
            ]
          )
    ]
)
