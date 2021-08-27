generate-proto:
	protoc ./Sources/EtcdProto/kv.proto \
	--proto_path=./Sources/EtcdProto/ \
	--grpc-swift_opt=Visibility=Public \
	--grpc-swift_out=./Sources/EtcdProto/ \
	--swift_opt=Visibility=Public \
	--swift_out=./Sources/EtcdProto/
