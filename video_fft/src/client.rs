pub mod infer {
    tonic::include_proto!("myrdvideoinferinfer");
}

use std::fs;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        return Err("Need atleast 1 commandline argument for the video file");
    } else {
        let data = fs::read(args[1]).expect("Failed reading image file");
        let img = infer::Image { image_data: data };
        let mut client = infer::infer_client::InferClient::connect("http://127.0.0.1:8001").await?;
        let res = client.do_infer(img).await?;
        println!("{:?}", res);
        return Ok(());
    }
}
