generate-proto:
	protoc ./Sources/EtcdProto/kv.proto \
	--proto_path=./Sources/EtcdProto/ \
	--grpc-swift_opt=Visibility=Public \
	--grpc-swift_out=./Sources/EtcdProto/ \
	--swift_opt=Visibility=Public \
	--swift_out=./Sources/EtcdProto/

gen-all-proto:
	protoc ./*.proto \
	--proto_path=. \
	--grpc-swift_opt=Visibility=Public \
	--grpc-swift_out=. \
	--swift_opt=Visibility=Public \
	--swift_out=. \
	--plugin=protoc-gen-swift=./protoc-gen-swift \
	--plugin=protoc-gen-grpc-swift=./protoc-gen-grpc-swift
