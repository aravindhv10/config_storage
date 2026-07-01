use clap::Parser;
use futures::StreamExt;
use std::io::Read;

fn get_dependency_by_pid_blocking(PID: i64) -> std::collections::HashSet<std::path::PathBuf> {
    jwalk::WalkDir::new(std::path::PathBuf::from("/proc/").join(PID.to_string().as_str()))
        .sort(true)
        .into_iter()
        .filter_map(|e| e.ok())
        .map(|e| e.path())
        .filter(|e| !e.is_dir())
        .filter_map(|e| std::fs::read_link(e).ok())
        .filter(|e| !e.starts_with("/dev"))
        .filter(|e| e.starts_with("/"))
        .collect()
}

async fn get_dependency_by_pid_async(
    PID: i64,
) -> anyhow::Result<std::collections::HashSet<std::path::PathBuf>> {
    let res = tokio::task::spawn_blocking(move || get_dependency_by_pid_blocking(PID)).await?;
    Ok(res)
}

fn do_mmap_blocking(inpath: impl AsRef<std::path::Path>) -> anyhow::Result<memmap2::MmapMut> {
    tracing::info!("Got argument {:?} for mmap + mlock", inpath.as_ref());

    let file = std::fs::File::open(inpath.as_ref())?;
    tracing::info!("Opened file");
    let mut res = unsafe { memmap2::MmapMut::map_mut(&file) }?;
    tracing::info!("Performed mmap");
    let lock =
        unsafe { rustix::mm::mlock(res.as_mut_ptr() as *mut std::os::raw::c_void, res.len()) }?;

    println!("pid={}", std::process::id());

    let status = std::fs::read_to_string("/proc/self/status")?;
    for line in status.lines() {
        if line.starts_with("VmLck:") || line.starts_with("VmRSS:") {
            println!("{line}");
        }
    }

    Ok(res)
}

async fn do_mmap_async(inpath: impl AsRef<std::path::Path>) -> anyhow::Result<memmap2::MmapMut> {
    tracing::info!("got argument {:?} for mapping", inpath.as_ref());
    let inpath = std::path::PathBuf::from(inpath.as_ref());
    let res = tokio::task::spawn_blocking(move || do_mmap_blocking(inpath)).await??;
    Ok(res)
}

async fn do_mlock_of_file(
    inpath: std::collections::HashSet<std::path::PathBuf>,
) -> Vec<memmap2::MmapMut> {
    tracing::info!(
        "Inside do_mlock_of_file for mlock. Got the args {:?}",
        inpath
    );
    futures::stream::iter(inpath.into_iter())
        .map(|e| do_mmap_async(e))
        .buffer_unordered(8)
        .collect::<Vec<_>>()
        .await
        .into_iter()
        .filter_map(|e| e.ok())
        .collect::<Vec<_>>()
}

fn get_dependency_main() -> std::collections::HashSet<std::path::PathBuf> {
    include_str!("./mlockffmpeg.txt")
        .split('\n')
        .map(|e| std::path::PathBuf::from(e))
        .filter(|e| !e.starts_with("/dev"))
        .filter(|e| e.starts_with("/"))
        .collect()
}

pub async fn do_default_mlocks() -> Vec<memmap2::MmapMut> {
    do_mlock_of_file(get_dependency_main()).await
}

// #[derive(Parser, Debug)]
// #[command(version, about, long_about = None)]
// struct Args {
//     #[arg(short, long, default_value_t = -1)]
//     pid: i64,
// }

// #[tokio::main]
// async fn main() -> anyhow::Result<()> {
//     let args = Args::parse();

//     if args.pid > 0 {
//         let res = get_dependency_by_pid_async(args.pid).await?;
//         let res = do_mlock_of_file(res).await;
//         println!("{}", res.len());
//     } else {
//         let res = do_mlock_of_file(get_dependency_main()).await;
//         println!("{}", res.len());
//     }

//     Ok(())
// }
