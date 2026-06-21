pub struct blob_hash {
    hash: blake3::Hash,
}

impl blob_hash {
    pub fn new_from_slice(inblob: &[u8]) -> Self {
        Self {
            hash: blake3::hash(inblob),
        }
    }

    pub fn new_from_file(infilepath: impl AsRef<std::path::Path>) -> anyhow::Result<Self> {
        let file: std::fs::File = std::fs::File::open(infilepath.as_ref())?;
        let mmap_result = unsafe { memmap2::Mmap::map(&file) }?;
        Ok(Self::new_from_slice(&mmap_result))
    }

    pub fn get_hash(&self) -> &[u8] {
        self.hash.as_slice()
    }

    pub fn get_hash_string(&self) -> String {
        return c32::encode(self.get_hash());
    }
}
