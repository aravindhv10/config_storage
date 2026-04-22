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

    return Ok(());
}
