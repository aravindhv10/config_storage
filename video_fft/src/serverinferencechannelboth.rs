use crate::inferencerelated;
use crate::inferencerelatedimage;
use crate::serverinferencechannel;
use crate::serverinferencechannelimage;
use crate::videofft;
use crate::videoview;

const NUM_BATCHES_IN_VIDEO: u8 = 2;

pub struct combined_infer {
    infer_rd: serverinferencechannel::inference_pair,
    infpairimage: serverinferencechannelimage::inference_pair,
}

impl combined_infer {
    pub fn new() -> Self {
        Self {
            infer_rd: serverinferencechannel::inference_pair::new(),
            infpairimage: serverinferencechannelimage::inference_pair::new(),
        }
    }

    pub fn do_infer_on_video_file(
        &self,
        path_file_video_input: &str,
    ) -> anyhow::Result<(
        Vec<inferencerelated::infer_results>,
        Vec<inferencerelatedimage::infer_results>,
    )> {
        let slicer = videoview::video_slicer_piped::new(
            /*path_file_video_input: String =*/ path_file_video_input.to_string(),
            /*fps: f32 =*/ 8 as f32,
            /*size_x: u16 =*/ 1280 as u16,
            /*size_y: u16 =*/ 720 as u16,
            /*size_c: u8 =*/ 3 as u8,
            /*clean_video: bool =*/ true,
        )?;

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

        let image_infer_results = self
            .infpairimage
            .do_infer_on_image_tensor(image_batch_tensor)?;

        let mut list_video_fft_tensor = videofft::fft_video::windowed_from_torch_video_tensor(
            /*tensor_video_input: &tch::Tensor =*/ &video_tensor,
            /*use_gpu: bool =*/ true,
        )?;

        drop(video_tensor);
        drop(slicer);

        let rd_infer_results = self
            .infer_rd
            .do_infer_on_fft_tensor(list_video_fft_tensor)?;

        return Ok((rd_infer_results, image_infer_results));
    }
}
