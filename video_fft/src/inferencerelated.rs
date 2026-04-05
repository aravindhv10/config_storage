use crate::export;
use crate::videofft;

#[repr(C)]
#[derive(Clone, Copy, Default)]
pub struct infer_results {
    pub p_calm: f32,
    pub p_contraversial: f32,
    pub p_rd: f32,
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
        println!("batch size called with : {}", batch_size);
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

        let num_batches: usize = vals.len() / (self.batch_size as usize);

        let mut ret = Vec::<infer_results>::with_capacity(vals.len());

        let blob_source_base = vals.as_mut_ptr();
        let blob_destination_base = ret.as_mut_ptr();

        for i in 0..num_batches {
            unsafe {
                export::run_infer_slave(
                    /*in_: *mut ::std::os::raw::c_void =*/ self.slave,
                    /*blob_source: *mut ::std::os::raw::c_void =*/
                    blob_source_base.add(i * (self.batch_size as usize))
                        as *mut ::std::os::raw::c_void,
                    /*blob_destination: *mut ::std::os::raw::c_void =*/
                    blob_destination_base.add(i * (self.batch_size as usize))
                        as *mut ::std::os::raw::c_void,
                )
            };
        }

        unsafe {
            ret.set_len(vals.len());
        };

        return Ok(ret);
    }
}
