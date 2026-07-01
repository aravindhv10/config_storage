use crate::filestore;
use crate::hasher;
use crate::inferencerelated;
use crate::inferencerelatedimage;
use crate::serverinferencechannel;
use crate::serverinferencechannelimage;
use crate::videofft;
use crate::videoview;

const NUM_BATCHES_IN_VIDEO: u8 = 4;

pub struct combined_infer {
    infer_rd: serverinferencechannel::inference_pair,
    infpairimage: serverinferencechannelimage::inference_pair,
    file_store: filestore::file_store,
}

#[derive(
    Debug, serde::Serialize, serde::Deserialize, rkyv::Archive, rkyv::Deserialize, rkyv::Serialize,
)]
pub struct combined_results {
    pub results_video: Vec<inferencerelated::infer_results>,
    pub results_image: Vec<inferencerelatedimage::infer_results>,
}

impl combined_infer {
    pub async fn new() -> anyhow::Result<Self> {
        tracing::warn!("Constructing serverinferencechannelboth::combined_infer");
        Ok(Self {
            infer_rd: serverinferencechannel::inference_pair::new().await?,
            infpairimage: serverinferencechannelimage::inference_pair::new(),
            file_store: filestore::file_store::new().await?,
        })
    }

    pub async fn do_infer_on_video_file(
        &self,
        key: &hasher::blob_hash,
    ) -> anyhow::Result<combined_results> {
        tracing::debug!("Reading the video file using ffmpeg");

        let slicer = {
            let mmap = self
                .file_store
                .get_raw_tensor(
                    &key, /*fps =*/ 8 as f32, /*size_x =*/ 1280, /*size_y =*/ 720,
                )
                .await?;
            videoview::video_slicer_mapped::new(
                mmap, /*fps =*/ 8 as f32, /*size_x =*/ 1280, /*size_y =*/ 720,
                /*size_c =*/ 3,
            )
        }?;

        let video_tensor = slicer.get_video_tensor()?;

        let image_batch_tensor: tch::Tensor = {
            const end_index: u8 =
                (serverinferencechannelimage::GOOD_BATCH_SIZE * NUM_BATCHES_IN_VIDEO);
            let image_indices: std::vec::Vec<i64> = (0..end_index)
                .map(|x: u8| ((video_tensor.size()[0] - 1) * (x as i64)) / ((end_index - 1) as i64))
                .collect();

            let image_indices_tensor = tch::Tensor::from_slice(image_indices.as_slice());

            video_tensor.index_select(/*dim =*/ 0, /*index =*/ &image_indices_tensor)
        };
        tracing::debug!("Constructed the image tensor.");

        let image_infer_results = self
            .infpairimage
            .do_infer_on_image_tensor(image_batch_tensor)?;
        tracing::debug!("Ran image inference.");

        let mut list_video_fft_tensor = videofft::fft_video::windowed_from_torch_video_tensor(
            /*tensor_video_input: &tch::Tensor =*/ &video_tensor,
            /*use_gpu: bool =*/ true,
        )?;

        drop(video_tensor);
        drop(slicer);

        let rd_infer_results = self
            .infer_rd
            .do_infer_on_fft_tensor(list_video_fft_tensor)?;
        tracing::debug!("Done video inference.");

        return Ok(combined_results {
            results_video: rd_infer_results,
            results_image: image_infer_results,
        });
    }
}
