generate-proto:
	protoc ./Sources/EtcdProto/kv.proto \
	--proto_path=./Sources/EtcdProto/ \
	--grpc-swift_opt=Visibility=Public \
	--grpc-swift_out=./Sources/EtcdProto/ \
	--swift_opt=Visibility=Public \
	--swift_out=./Sources/EtcdProto/

gen-all-proto:
	protoc ./Sources/EtcdProto/*.proto \
	--proto_path=./Sources/EtcdProto/ \
	--grpc-swift_opt=Visibility=Public \
	--grpc-swift_out=./Sources/EtcdProto/ \
	--swift_opt=Visibility=Public \
	--swift_out=./Sources/EtcdProto/ \
	--plugin=protoc-gen-swift=./protoc-gen-swift \
	--plugin=protoc-gen-grpc-swift=./protoc-gen-grpc-swift

download-proto:
	curl -o auth.proto https://raw.githubusercontent.com/etcd-io/jetcd/master/jetcd-core/src/main/proto/auth.proto
	curl -o election.proto https://raw.githubusercontent.com/etcd-io/jetcd/master/jetcd-core/src/main/proto/election.proto
	curl -o kv.proto https://raw.githubusercontent.com/etcd-io/jetcd/master/jetcd-core/src/main/proto/kv.proto
	curl -o lock.proto https://raw.githubusercontent.com/etcd-io/jetcd/master/jetcd-core/src/main/proto/lock.proto
	curl -o rpc.proto https://raw.githubusercontent.com/etcd-io/jetcd/master/jetcd-core/src/main/proto/rpc.proto
