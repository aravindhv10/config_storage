#!/bin/sh
export AWS_ENDPOINT_URL='http://gpu17:11110'
export AWS_DEFAULT_REGION='garage'
export AWS_ACCESS_KEY_ID='GKbcc09b0c3ef1deaa7e8ad122'
export AWS_SECRET_ACCESS_KEY='187fefcddecafcdfe16f3f02ea18c4f0b20c673795bc2919d85eef5e7cb13819'

juicefs format \
    '--storage' s3 \
    '--bucket' "${AWS_ENDPOINT_URL}/juicefs" \
    '--access-key' "${AWS_ACCESS_KEY_ID}" \
    '--secret-key' "${AWS_SECRET_ACCESS_KEY}" \
    "tikv://10.10.8.14:11100,10.10.8.16:11100,10.10.8.17:11100/juicefs" \
    myjfs ;
