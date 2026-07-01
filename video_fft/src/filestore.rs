use crate::hasher;

pub struct file_store {
    prefix_raw: std::path::PathBuf,
    prefix_raw_tmp: std::path::PathBuf,
    prefix_video: std::path::PathBuf,
    prefix_video_tmp: std::path::PathBuf,
}

impl file_store {
    pub async fn new() -> anyhow::Result<Self> {
        let prefix = std::path::PathBuf::from("/dev/shm/RD");

        let prefix_raw = prefix.join("raw");
        let prefix_raw_tmp = prefix.join("raw_tmp");
        let prefix_video = prefix.join("video");
        let prefix_video_tmp = prefix.join("video");

        tokio::fs::create_dir_all(/*path =*/ &prefix_raw).await?;
        tokio::fs::create_dir_all(/*path =*/ &prefix_raw_tmp).await?;
        tokio::fs::create_dir_all(/*path =*/ &prefix_video).await?;
        tokio::fs::create_dir_all(/*path =*/ &prefix_video_tmp).await?;

        return Ok(Self {
            prefix_raw: prefix_raw,
            prefix_raw_tmp: prefix_raw_tmp,
            prefix_video: prefix_video,
            prefix_video_tmp: prefix_video_tmp,
        });
    }

    pub async fn get_all_files(&self) -> Vec<std::path::PathBuf> {
        let prefix_video = self.prefix_video.clone();

        let res: Vec<std::path::PathBuf> =
            tokio::task::spawn_blocking(|| -> Vec<std::path::PathBuf> {
                jwalk::WalkDir::new(prefix_video)
                    .into_iter()
                    .filter_map(|e| e.ok())
                    .map(|e| e.path())
                    .collect()
            })
            .await
            .expect("Failed to get list of files");

        res
    }

    pub async fn get_all_files_with_hash(&self) -> Vec<(hasher::blob_hash, std::path::PathBuf)> {
        let prefix_video = self.prefix_video.clone();

        let res =
            tokio::task::spawn_blocking(|| -> Vec<(hasher::blob_hash, std::path::PathBuf)> {
                jwalk::WalkDir::new(prefix_video)
                    .into_iter()
                    .filter_map(|e| e.ok())
                    .map(|e| e.path())
                    .map(|e| match hasher::blob_hash::new_from_tmp_file(&e) {
                        Ok(o) => Some((o, e)),
                        Err(e) => None,
                    })
                    .flatten()
                    .collect()
            })
            .await
            .expect("Failed to scan /dev/shm/video");

        res
    }

    #[inline(always)]
    pub fn get_path_video(&self, key: &hasher::blob_hash) -> std::path::PathBuf {
        match key.get_file_path() {
            Some(p) => p.clone(),
            None => self.prefix_video.join(key.get_hash_string()),
        }
    }

    #[inline(always)]
    pub fn get_path_raw(&self, key: &hasher::blob_hash) -> std::path::PathBuf {
        self.prefix_raw.join(key.get_hash_string())
    }

    #[inline(always)]
    fn get_path_video_tmp(&self, key: &hasher::blob_hash) -> std::path::PathBuf {
        self.prefix_video_tmp.join(key.get_hash_string())
    }

    #[inline(always)]
    fn get_path_raw_tmp(&self, key: &hasher::blob_hash) -> std::path::PathBuf {
        self.prefix_raw_tmp.join(key.get_hash_string())
    }

    pub async fn put_content(
        &self,
        key: &hasher::blob_hash,
        value: &Vec<u8>,
    ) -> anyhow::Result<std::path::PathBuf> {
        let path_tmp = self.get_path_video_tmp(key);
        let path_video = self.get_path_video(key);
        let _ = tokio::fs::write(&path_tmp, value.as_slice()).await?;
        let _ = tokio::fs::rename(/*from =*/ &path_tmp, /*to =*/ &path_video).await?;
        return Ok(path_video);
    }

    pub async fn get_raw_tensor(
        &self,
        key: &hasher::blob_hash,
        fps: f32,
        size_x: u16,
        size_y: u16,
    ) -> anyhow::Result<memmap2::Mmap> {
        let path_file_video = self.get_path_video(key);
        let path_file_raw_tmp = self.get_path_raw_tmp(key);

        let res = tokio::process::Command::new("ffmpeg")
            .arg("-i")
            .arg(&path_file_video)
            .arg("-vf")
            .arg(format!("fps={},scale={}:{}", fps, size_x, size_y).as_str())
            .arg("-nostdin")
            .arg("-loglevel")
            .arg("quiet")
            .arg("-f")
            .arg("rawvideo")
            .arg("-pix_fmt")
            .arg("rgb24")
            .arg(&path_file_raw_tmp)
            .status()
            .await;

        match key.get_file_path() {
            None => {
                tokio::fs::remove_file(&path_file_video).await?;
                drop(path_file_video);
            }
            Some(p) => {
                tracing::warn!("Not deleting non-temporary video {:?}", p);
                drop(path_file_video);
            }
        }

        let res = match res {
            Ok(o) => match o.code() {
                None => -128,
                Some(e) => e,
            },
            Err(e) => -128,
        };

        if res != 0 {
            tokio::fs::remove_file(&path_file_raw_tmp).await?;
            drop(path_file_raw_tmp);
            tracing::error!("FFMPEG error code {}", res);
            return Err(anyhow::format_err!("FFMPEG error code {}", res));
        }

        let path_file_raw = self.get_path_raw(key);

        match tokio::fs::rename(&path_file_raw_tmp, &path_file_raw).await {
            Ok(_) => {
                drop(path_file_raw_tmp);
            }
            Err(e) => {
                tokio::fs::remove_file(&path_file_raw_tmp).await?;
                tracing::error!(
                    "Unable to move temporary file {:?} to actual raw file {:?}",
                    &path_file_raw_tmp,
                    &path_file_raw
                );
                return Err(anyhow::format_err!(
                    "Unable to move temporary file {:?} to actual raw file {:?}",
                    &path_file_raw_tmp,
                    &path_file_raw
                ));
            }
        };

        let mmap = tokio::task::spawn_blocking(move || {
            let file = match std::fs::File::open(&path_file_raw) {
                Ok(o) => {
                    std::fs::remove_file(path_file_raw)?;
                    o
                }
                Err(e) => {
                    std::fs::remove_file(&path_file_raw)?;
                    tracing::error!("open on raw file {:?} failed due to {}", &path_file_raw, e);
                    return Err(anyhow::format_err!(
                        "open on raw file {:?} failed due to {}",
                        &path_file_raw,
                        e
                    ));
                }
            };

            let mmap_result = unsafe { memmap2::Mmap::map(&file) };
            let mmap_result = mmap_result?;

            Ok(mmap_result)
        })
        .await??;

        return Ok((mmap));
    }

    #[inline(always)]
    pub fn get_path(&self, key: &hasher::blob_hash) -> std::path::PathBuf {
        self.get_path_video(key)
    }

    #[inline(always)]
    pub async fn get_tensor_from_video(
        &self,
        key: &hasher::blob_hash,
        value: &Vec<u8>,
        fps: f32,
        size_x: u16,
        size_y: u16,
    ) -> anyhow::Result<memmap2::Mmap> {
        let res = self.put_content(key, value).await?;
        self.get_raw_tensor(key, fps, size_x, size_y).await
    }
}
