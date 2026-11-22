#!/bin/sh
aws --endpoint-url 'http://127.0.0.1:8100' s3 mb 's3://testing'
aws --endpoint-url 'http://127.0.0.1:8100' s3 ls 's3://'
