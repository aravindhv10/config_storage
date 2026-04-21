use crate::export;

pub struct named_semaphore {
    slave: *mut ::std::os::raw::c_void,
}

impl Drop for named_semaphore {
    fn drop(&mut self) {
        unsafe { export::named_semaphore_delete(self.slave) };
    }
}

impl named_semaphore {
    pub fn new(name: &str, num: i32) -> anyhow::Result<Self> {
        let name = std::ffi::CString::new(name)?;
        return Ok(Self {
            slave: unsafe {
                export::named_semaphore_new(
                    /*name: *const ::std::os::raw::c_char =*/ name.as_ptr(),
                    /*num: ::std::os::raw::c_int =*/ num,
                )
            },
        });
    }

    pub fn l(&mut self) {
        unsafe {
            export::named_semaphore_l(/*in_: *mut ::std::os::raw::c_void =*/ self.slave)
        };
    }

    pub fn r(&mut self) {
        unsafe {
            export::named_semaphore_r(/*in_: *mut ::std::os::raw::c_void =*/ self.slave)
        };
    }
}

pub struct unnamed_semaphore {
    slave: *mut ::std::os::raw::c_void,
}

impl Drop for unnamed_semaphore {
    fn drop(&mut self) {
        unsafe { export::unnamed_semaphore_delete(self.slave) };
    }
}

impl unnamed_semaphore {
    pub fn new(num: i32) -> anyhow::Result<Self> {
        return Ok(Self {
            slave: unsafe {
                export::unnamed_semaphore_new(/*num: ::std::os::raw::c_int =*/ num)
            },
        });
    }

    pub fn l(&mut self) {
        unsafe {
            export::unnamed_semaphore_l(/*in_: *mut ::std::os::raw::c_void =*/ self.slave)
        };
    }

    pub fn r(&mut self) {
        unsafe {
            export::unnamed_semaphore_r(/*in_: *mut ::std::os::raw::c_void =*/ self.slave)
        };
    }
}
