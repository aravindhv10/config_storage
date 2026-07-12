use prost::Message;

pub struct key_value_db {
    diskdb: fjall::Database,
    items_Grpcvideopredictionreply: fjall::Keyspace,
}

impl key_value_db {
    pub fn new(path: impl AsRef<std::path::Path>) -> anyhow::Result<std::sync::Arc<Self>> {
        let diskdb: fjall::Database = fjall::Database::builder(path.as_ref()).open()?;

        let items_Grpcvideopredictionreply = diskdb.keyspace(
            "Grpcvideopredictionreply",
            fjall::KeyspaceCreateOptions::default,
        )?;

        let ret = std::sync::Arc::new(Self {
            diskdb: diskdb,
            items_Grpcvideopredictionreply: items_Grpcvideopredictionreply,
        });

        Ok(ret)
    }

    pub fn put_Grpcvideopredictionreply(
        &self,
        key: &crate::hasher::blob_hash,
        value: &crate::Grpcvideopredictionreply,
    ) -> anyhow::Result<()> {
        let mut buf: Vec<u8> = Vec::with_capacity(value.encoded_len());

        value.encode(&mut buf)?;

        self.items_Grpcvideopredictionreply
            .insert(key.get_hash(), buf)?;

        Ok(())
    }

    pub fn get_Grpcvideopredictionreply(
        &self,
        key: &crate::hasher::blob_hash,
    ) -> anyhow::Result<crate::Grpcvideopredictionreply> {
        let bytes = match self.items_Grpcvideopredictionreply.get(key.get_hash())? {
            Some(o) => o,
            None => {
                return Err(anyhow::format_err!("Key not found in db"));
            }
        };

        let res = crate::Grpcvideopredictionreply::decode(bytes.as_slice())?;

        match res.vidver {
            Some(o) => {
                if (crate::version::major_version() == o.major)
                    && (crate::version::minor_version() == o.minor)
                {
                    return Ok(res);
                } else {
                    return Err(anyhow::format_err!(
                        "Cached version mismatch with running model"
                    ));
                }
            }
            None => {
                return Err(anyhow::format_err!(
                    "Cached version mismatch with running model"
                ));
            }
        }
    }
}
