use aws_config::BehaviorVersion;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let config = aws_config::load_from_env().await;

    let s3_config = aws_sdk_s3::config::Builder::from(&config)
        .force_path_style(true)
        .build();

    let client = aws_sdk_s3::Client::from_conf(s3_config);
    let bucket = "rdvideodataset";

    let list_output = client.list_objects_v2().bucket(bucket).send().await?;

    for object in list_output.contents() {
        println!("Key: {}", object.key().unwrap_or("Unknown"));
    }

    let key = "RD/videos_organized_hashed/test/A/769d26f8e5cb4d8a27b3e0a3c48e39918a470f7ed20c3c18c1d3cad8a4331b949667bfcda1040bd8000973510d6579787937290873a63eebdb441442a688ac1a.mp4";
    println!("\n--- Downloading {} ---", key);
    let get_output = client.get_object().bucket(bucket).key(key).send().await?;
    let data = get_output.body.collect().await?.into_bytes();
    println!("Downloaded {} bytes", data.len());

    // --- GENERATING A PRESIGNED URL ---
    println!("\n--- Generating Presigned URL (Valid for 1 hour) ---");
    let expires_in = std::time::Duration::from_secs(3600);
    let presigned_request = client
        .get_object()
        .bucket(bucket)
        .key(key)
        .presigned(aws_sdk_s3::presigning::PresigningConfig::expires_in(
            expires_in,
        )?)
        .await?;

    println!("URL: {}", presigned_request.uri());

    return Ok(());
}
