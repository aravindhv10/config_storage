use crate::export;
use tch::IndexOp;

#[repr(C)]
#[derive(Clone, Copy, Debug)]
pub struct infer_results {
    pub negative: f32,
    pub positive: f32,
}

impl Default for infer_results {
    fn default() -> Self {
        infer_results {
            negative: 0 as f32,
            positive: 0 as f32,
        }
    }
}

pub struct infer_slave {
    slave: *mut ::std::os::raw::c_void,
    batch_size: ::std::os::raw::c_uchar,
}

impl Drop for infer_slave {
    fn drop(&mut self) {
        unsafe { export::delete_infer_slave_image_cv_usability(self.slave) };
    }
}

impl infer_slave {
    pub fn new(batch_size: u8) -> Self {
        tracing::info!("Constructing the image infer_slave");
        Self {
            slave: unsafe { export::new_infer_slave_image_cv_usability(batch_size) },
            batch_size: batch_size,
        }
    }

    pub fn infer(&mut self, vals: &tch::Tensor) -> anyhow::Result<Vec<f32>> {
        let size: Vec<i64> = vals.size();

        if ((size[0] as usize) % (self.batch_size as usize)) != 0 {
            tracing::error!(
                "The input vector length should be a multiple of batch size {}",
                self.batch_size
            );
            return Err(anyhow::format_err!(
                "The input vector length should be a multiple of batch size"
            ));
        }

        let num_batches: usize = (size[0] as usize) / (self.batch_size as usize);

        let mut ret = Vec::<infer_results>::with_capacity(size[0] as usize);
        let blob_destination_base = ret.as_mut_ptr();

        for i in 0..num_batches {
            let begin_t = (i as i64) * (self.batch_size as i64);
            let end_t = begin_t + (self.batch_size as i64);

            tracing::debug!("getting the range {} {}", begin_t, end_t);

            let current_batch_tensor = {
                const SY: i64 = 720;
                const SX: i64 = 1280;
                const SC: i64 = 3;
                const D: i64 = (SX - SY) >> 1;
                const BEGIN_X: i64 = D;
                const END_X: i64 = BEGIN_X + SY;
                let cropped_tensor = vals.i((begin_t..end_t, .., BEGIN_X..END_X, ..));
                let nchw_tensor = cropped_tensor.permute(&[0, 3, 1, 2]);

                let interpolated_nchw =
                    nchw_tensor.upsample_bicubic2d(&[448, 448], false, None, None);

                let final_tensor = interpolated_nchw.permute(&[0, 2, 3, 1]);

                final_tensor.contiguous()
            };

            let blob_source_base = current_batch_tensor.data_ptr();

            let status = unsafe {
                export::run_infer_slave_image_cv_usability(
                    self.slave,
                    blob_source_base as *mut ::std::os::raw::c_void,
                    blob_destination_base.add(i * (self.batch_size as usize))
                        as *mut ::std::os::raw::c_void,
                )
            } as i32;

            if status != 0 {
                tracing::error!("Inference failed with error code {}", status);
            }
        }

        unsafe { ret.set_len(size[0] as usize) };

        let ret: Vec<f32> = ret.into_iter().map(|i| i.positive).collect();

        return Ok(ret);
    }
}
