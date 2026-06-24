use crate::hasher;

pub struct file_store {
    prefix_video: std::path::PathBuf,
    prefix_tmp: std::path::PathBuf,
}

impl file_store {
    pub fn new() -> anyhow::Result<Self> {
        let prefix = std::path::PathBuf::from("/dev/shm/RD");

        let prefix_video = prefix.join("video");
        let prefix_tmp = prefix.join("tmp");

        std::fs::create_dir_all(/*path =*/ &prefix_tmp);
        std::fs::create_dir_all(/*path =*/ &prefix_video);

        return Ok(Self {
            prefix_video: prefix_video,
            prefix_tmp: prefix_tmp,
        });
    }

    #[inline(always)]
    pub fn get_all_files(&self) -> Vec<std::path::PathBuf> {
        jwalk::WalkDir::new(&self.prefix_video)
            .into_iter()
            .filter_map(|e| e.ok())
            .map(|e| e.path())
            .collect()
    }

    #[inline(always)]
    pub fn get_all_files_with_hash(&self) -> Vec<(hasher::blob_hash, std::path::PathBuf)> {
        jwalk::WalkDir::new(&self.prefix_video)
            .into_iter()
            .filter_map(|e| e.ok())
            .map(|e| e.path())
            .map(|e| match hasher::blob_hash::new_from_file(&e) {
                Ok(o) => Some((o, e)),
                Err(e) => None,
            })
            .flatten()
            .collect()
    }

    pub async fn put_content(
        &self,
        key: &hasher::blob_hash,
        value: &Vec<u8>,
    ) -> anyhow::Result<std::path::PathBuf> {
        let path_tmp = self.prefix_tmp.join(key.get_hash_string());
        let path_video = self.prefix_video.join(key.get_hash_string());
        let _ = tokio::fs::write(&path_tmp, value.as_slice()).await?;
        let _ = tokio::fs::rename(/*from =*/ &path_tmp, /*to =*/ &path_video).await?;
        return Ok(path_video);
    }

    #[inline(always)]
    pub fn get_path(&self, key: &hasher::blob_hash) -> std::path::PathBuf {
        self.prefix_video.join(key.get_hash_string())
    }
}
