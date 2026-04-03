use crate::export;
use crate::videofft;

#[derive(Clone)]
pub struct infer_results {
    p_calm: f32,
    p_contraversial: f32,
    p_rd: f32,
}

impl Default for infer_results {
    fn default() -> Self {
        infer_results {
            p_calm: 0 as f32,
            p_contraversial: 0 as f32,
            p_rd: 0 as f32,
        }
    }
}

pub struct infer_slave {
    slave: *mut ::std::os::raw::c_void,
    batch_size: ::std::os::raw::c_uchar,
}

impl Drop for infer_slave {
    fn drop(&mut self) {
        unsafe { export::delete_infer_slave(self.slave) };
    }
}

impl infer_slave {
    pub fn new(batch_size: u8) -> Self {
        Self {
            slave: unsafe { export::new_infer_slave(batch_size) },
            batch_size: batch_size,
        }
    }

    pub fn infer(
        &mut self,
        vals: &mut Vec<videofft::fft_video>,
    ) -> anyhow::Result<Vec<infer_results>> {
        if (vals.len() % (self.batch_size as usize)) != 0 {
            return Err(anyhow::format_err!(
                "The input vector length should be a multiple of batch size"
            ));
        }

        let mut ret = Vec::<infer_results>::with_capacity(vals.len());

        let mut output = Vec::<infer_results>::with_capacity(self.batch_size as usize);
        output.resize_with(self.batch_size as usize, Default::default);

        for i in (vals.chunks_exact_mut(self.batch_size as usize)) {
            unsafe {
                export::run_infer_slave(
                    /*in_: *mut ::std::os::raw::c_void =*/ self.slave,
                    /*blob_source: *mut ::std::os::raw::c_void =*/
                    i.as_mut_ptr() as *mut ::std::os::raw::c_void,
                    /*blob_destination: *mut ::std::os::raw::c_void =*/
                    output.as_mut_ptr() as *mut ::std::os::raw::c_void,
                )
            };

            ret.extend(output.iter().cloned());
        }

        return Ok(ret);
    }
}
