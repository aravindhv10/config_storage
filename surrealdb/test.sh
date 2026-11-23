#!/bin/sh
curl -s -X POST 'http://127.0.0.1:8101/sql' \
  -u 'cloudphysician:7*Bellary' \
  -H 'Surreal-NS: main' \
  -H 'Surreal-DB: main' \
  -H 'Accept: application/json' \
  -d 'SELECT event_name, bucket, key, received_at FROM s3_event ORDER BY received_at;'
