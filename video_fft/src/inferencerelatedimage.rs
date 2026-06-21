use crate::export;
use tch::IndexOp;

#[repr(C)]
#[derive(
    Clone,
    Copy,
    Debug,
    serde::Serialize,
    serde::Deserialize,
    rkyv::Archive,
    rkyv::Serialize,
    rkyv::Deserialize,
)]
pub struct infer_results {
    pub ARM: i64,
    pub RAIL: i64,
    pub LEG: i64,
    pub POS: i64,
    pub BED: i64,
}

pub struct infer_slave {
    slave: *mut ::std::os::raw::c_void,
    batch_size: ::std::os::raw::c_uchar,
}

impl Default for infer_results {
    fn default() -> Self {
        infer_results {
            ARM: 0 as i64,
            RAIL: 0 as i64,
            LEG: 0 as i64,
            POS: 0 as i64,
            BED: 0 as i64,
        }
    }
}

impl infer_results {
    pub fn bed_status(&self) -> f32 {
        if self.BED == 1 {
            return 1 as f32;
        } else {
            return 0 as f32;
        }
    }
}

impl Drop for infer_slave {
    fn drop(&mut self) {
        unsafe { export::delete_infer_slave_image(self.slave) };
    }
}

impl infer_slave {
    pub fn new(batch_size: u8) -> Self {
        tracing::warn!("Constructing the image infer_slave");
        Self {
            slave: unsafe { export::new_infer_slave_image(batch_size) },
            batch_size: batch_size,
        }
    }

    pub fn infer(&mut self, vals: &tch::Tensor) -> anyhow::Result<Vec<infer_results>> {
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
                const sy: i64 = 720;
                const sx: i64 = 1280;
                const sc: i64 = 3;
                const d: i64 = (sx - sy) >> 1;
                const begin_x: i64 = d;
                const end_x: i64 = begin_x + sy;
                let cropped_tensor = vals.i((begin_t..end_t, .., begin_x..end_x, ..));
                let nchw_tensor = cropped_tensor.permute(&[0, 3, 1, 2]);

                let interpolated_nchw =
                    nchw_tensor.upsample_bicubic2d(&[448, 448], false, None, None);

                let final_tensor = interpolated_nchw.permute(&[0, 2, 3, 1]);

                final_tensor.contiguous()
            };

            let blob_source_base = current_batch_tensor.data_ptr();

            let status = unsafe {
                export::run_infer_slave_image(
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

        return Ok(ret);
    }
}
