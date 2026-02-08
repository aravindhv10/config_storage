#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let mut args: Vec<String> = std::env::args().collect();
    args[0] = "--progress".to_string();
    args.push(String::from("-avh"));

    let res = tokio::process::Command::new("rsync")
        .args(args)
        .status()
        .await?;

    match res.code() {
        None => {
            return Err(anyhow::format_err!(
                "Failed to start rsync, no return code found",
            ));
        }
        Some(c) => {
            if c == 0 {
                let _ = tokio::process::Command::new("sync").status().await?;
                let _ = tokio::process::Command::new("sync").status().await?;
                return Ok(());
            } else {
                return Err(anyhow::format_err!("Rsync failed with return code {}", c));
            }
        }
    }
}
