pub mod infer {
    tonic::include_proto!("myrdvideoinferinfer");
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        return Err(anyhow::format_err!(
            "Need atleast 1 commandline argument for the video file"
        ));
    }

    let data = tokio::fs::read(args[1].as_str()).await?;
    let payload = infer::Grpcvideodata { data: data };

    let mut client =
        infer::rdvideoinfer_client::RdvideoinferClient::connect("http://127.0.0.1:8001").await?;

    let res = client.doinfer(payload).await?.into_inner();
    for i in res.preds.iter() {
        println!("{:?}", res);
    }

    return Ok(());
}
