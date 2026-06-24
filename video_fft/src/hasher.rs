pub struct blob_hash {
    hash: blake3::Hash,
    string_rep: std::string::String,
}

impl blob_hash {
    #[inline(always)]
    pub fn new_from_slice(inblob: &[u8]) -> Self {
        let hash = blake3::hash(inblob);
        let string_rep = c32::encode(hash.as_slice());
        Self {
            hash: hash,
            string_rep: string_rep,
        }
    }

    pub fn new_from_file(infilepath: impl AsRef<std::path::Path>) -> anyhow::Result<Self> {
        let file: std::fs::File = std::fs::File::open(infilepath.as_ref())?;
        let mmap_result = unsafe { memmap2::Mmap::map(&file) }?;
        Ok(Self::new_from_slice(&mmap_result))
    }

    #[inline(always)]
    pub fn get_hash(&self) -> &[u8] {
        self.hash.as_slice()
    }

    #[inline(always)]
    pub fn get_hash_string(&self) -> &str {
        return &self.string_rep;
    }
}
