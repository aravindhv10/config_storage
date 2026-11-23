DEFINE NAMESPACE IF NOT EXISTS main;
USE NS main;
DEFINE DATABASE IF NOT EXISTS main;
USE DB main;

DEFINE TABLE IF NOT EXISTS s3_event SCHEMALESS PERMISSIONS NONE;

DEFINE API OVERWRITE "/rustfs/events"
    FOR post
        MIDDLEWARE api::timeout(5s)
        THEN {
            IF $request.query.token != "PUT_YOUR_SECRET_HERE" {
                RETURN { status: 403, body: "forbidden" };
            };

            FOR $r IN ($request.body.Records ?? []) {
                -- deterministic id, so a redelivered event overwrites instead of duplicating
                UPSERT s3_event:[$r.s3.bucket.name, $r.s3.object.key, $r.s3.object.sequencer, $r.eventName]
                CONTENT {
                    event_name:  $r.eventName,
                    event_time:  $r.eventTime,
                    bucket:      $r.s3.bucket.name,
                    key:         $r.s3.object.key,
                    size:        $r.s3.object.size,
                    etag:        $r.s3.object.eTag,
                    raw:         $r,
                    received_at: time::now()
                };
            };

            RETURN { status: 200, body: { ok: true } };
        };
