#!/bin/sh
cd "$(dirname -- "${0}")" 
'python3' '-m' 'grpc_tools.protoc' \
    '-I.' '--python_out=.' \
    '--grpc_python_out=.' \
    'infer.proto' \
;
exit '0'
