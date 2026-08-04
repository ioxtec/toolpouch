use std::slice;

pub const API_VERSION: u32 = 1;
pub const STATUS_OK: i32 = 0;
pub const STATUS_INVALID_ARGUMENT: i32 = 1;

#[unsafe(no_mangle)]
pub extern "C" fn toolpouch_engine_api_version() -> u32 {
    API_VERSION
}

/// Calculates CRC32 for a byte buffer and writes the result to `output`.
///
/// # Safety
///
/// `output` must point to writable `u32` storage. When `length` is greater
/// than zero, `bytes` must point to a readable buffer of at least `length`
/// bytes. The input and output pointers must remain valid for this call.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn toolpouch_engine_crc32(
    bytes: *const u8,
    length: usize,
    output: *mut u32,
) -> i32 {
    if output.is_null() || (bytes.is_null() && length > 0) {
        return STATUS_INVALID_ARGUMENT;
    }

    let input = if length == 0 {
        &[]
    } else {
        // SAFETY: The caller guarantees a readable buffer of `length` bytes.
        unsafe { slice::from_raw_parts(bytes, length) }
    };

    // SAFETY: `output` was validated above and the caller guarantees that it
    // points to writable storage for one `u32` value.
    unsafe { output.write(crc32(input)) };
    STATUS_OK
}

fn crc32(bytes: &[u8]) -> u32 {
    let mut crc = u32::MAX;

    for byte in bytes {
        crc ^= u32::from(*byte);
        for _ in 0..8 {
            let mask = 0_u32.wrapping_sub(crc & 1);
            crc = (crc >> 1) ^ (0xEDB8_8320 & mask);
        }
    }

    !crc
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reports_the_current_api_version() {
        assert_eq!(toolpouch_engine_api_version(), 1);
    }

    #[test]
    fn calculates_the_standard_crc32_test_vector() {
        assert_eq!(crc32(b"123456789"), 0xCBF4_3926);
    }

    #[test]
    fn rejects_a_missing_output_pointer() {
        let status = unsafe { toolpouch_engine_crc32(std::ptr::null(), 0, std::ptr::null_mut()) };

        assert_eq!(status, STATUS_INVALID_ARGUMENT);
    }
}
