use aws_config::BehaviorVersion;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let config = aws_config::load_from_env().await;
    println!("Hello, world!");
    return Ok(());
}
