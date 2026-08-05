use std::path::{Path, PathBuf};
use std::{slice, str};
use toolpouch_image::{
    ColorModel, Format, InspectError, OutputFormat, TransformError, TransformOptions,
};

pub const API_VERSION: u32 = 1;
pub const STATUS_OK: i32 = 0;
pub const STATUS_INVALID_ARGUMENT: i32 = 1;
pub const STATUS_IO_ERROR: i32 = 2;
pub const STATUS_UNSUPPORTED_FORMAT: i32 = 3;
pub const STATUS_INVALID_IMAGE: i32 = 4;
pub const STATUS_ENCODING_FAILED: i32 = 5;

#[repr(C)]
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub struct ToolPouchImageInfo {
    pub width: u32,
    pub height: u32,
    pub format: u32,
    pub color_model: u32,
    pub channel_count: u8,
    pub bits_per_channel: u8,
    pub has_alpha: u8,
    pub reserved: u8,
    pub file_size: u64,
}

#[repr(C)]
#[derive(Clone, Copy)]
pub struct ToolPouchImageMetadata {
    pub camera_make: [u8; 128],
    pub camera_model: [u8; 128],
    pub lens_model: [u8; 128],
    pub captured_at: [u8; 128],
    pub exposure_time: [u8; 128],
    pub aperture: [u8; 128],
    pub iso: [u8; 128],
    pub focal_length: [u8; 128],
    pub orientation: [u8; 128],
    pub latitude: f64,
    pub longitude: f64,
    pub has_location: u8,
    pub reserved: [u8; 7],
}

impl Default for ToolPouchImageMetadata {
    fn default() -> Self {
        Self {
            camera_make: [0; 128],
            camera_model: [0; 128],
            lens_model: [0; 128],
            captured_at: [0; 128],
            exposure_time: [0; 128],
            aperture: [0; 128],
            iso: [0; 128],
            focal_length: [0; 128],
            orientation: [0; 128],
            latitude: 0.0,
            longitude: 0.0,
            has_location: 0,
            reserved: [0; 7],
        }
    }
}

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

/// Inspects an image at a UTF-8 file path and writes its basic properties.
///
/// # Safety
///
/// `output` must point to writable `ToolPouchImageInfo` storage. `path_bytes`
/// must point to a readable UTF-8 buffer of `path_length` bytes. Both pointers
/// must remain valid for this call.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn toolpouch_image_inspect(
    path_bytes: *const u8,
    path_length: usize,
    output: *mut ToolPouchImageInfo,
) -> i32 {
    if output.is_null() || path_bytes.is_null() || path_length == 0 {
        return STATUS_INVALID_ARGUMENT;
    }

    // SAFETY: The caller guarantees a readable buffer of `path_length` bytes.
    let bytes = unsafe { slice::from_raw_parts(path_bytes, path_length) };
    let Ok(path) = str::from_utf8(bytes) else {
        return STATUS_INVALID_ARGUMENT;
    };

    let info = match toolpouch_image::inspect(Path::new(path)) {
        Ok(info) => info,
        Err(InspectError::Io) => return STATUS_IO_ERROR,
        Err(InspectError::UnsupportedFormat) => return STATUS_UNSUPPORTED_FORMAT,
        Err(InspectError::InvalidImage) => return STATUS_INVALID_IMAGE,
    };
    let ffi_info = ToolPouchImageInfo {
        width: info.width,
        height: info.height,
        format: format_code(info.format),
        color_model: color_model_code(info.color_model),
        channel_count: info.channel_count,
        bits_per_channel: info.bits_per_channel,
        has_alpha: u8::from(info.has_alpha),
        reserved: 0,
        file_size: info.file_size,
    };

    // SAFETY: `output` was validated above and the caller guarantees storage.
    unsafe { output.write(ffi_info) };
    STATUS_OK
}

/// Reads common EXIF fields from an image at a UTF-8 file path.
///
/// # Safety
///
/// The path buffer and writable output structure must remain valid for this call.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn toolpouch_image_read_metadata(
    path_bytes: *const u8,
    path_length: usize,
    output: *mut ToolPouchImageMetadata,
) -> i32 {
    let Some(path) = (unsafe { path_from_bytes(path_bytes, path_length) }) else {
        return STATUS_INVALID_ARGUMENT;
    };
    if output.is_null() {
        return STATUS_INVALID_ARGUMENT;
    }
    let metadata = match toolpouch_image::read_metadata(&path) {
        Ok(metadata) => metadata,
        Err(InspectError::Io) => return STATUS_IO_ERROR,
        Err(InspectError::UnsupportedFormat) => return STATUS_UNSUPPORTED_FORMAT,
        Err(InspectError::InvalidImage) => return STATUS_INVALID_IMAGE,
    };
    let mut result = ToolPouchImageMetadata::default();
    write_text(&mut result.camera_make, metadata.camera_make.as_deref());
    write_text(&mut result.camera_model, metadata.camera_model.as_deref());
    write_text(&mut result.lens_model, metadata.lens_model.as_deref());
    write_text(&mut result.captured_at, metadata.captured_at.as_deref());
    write_text(&mut result.exposure_time, metadata.exposure_time.as_deref());
    write_text(&mut result.aperture, metadata.aperture.as_deref());
    write_text(&mut result.iso, metadata.iso.as_deref());
    write_text(&mut result.focal_length, metadata.focal_length.as_deref());
    write_text(&mut result.orientation, metadata.orientation.as_deref());
    if let (Some(latitude), Some(longitude)) = (metadata.latitude, metadata.longitude) {
        result.latitude = latitude;
        result.longitude = longitude;
        result.has_location = 1;
    }
    // SAFETY: The caller guarantees writable storage for the output structure.
    unsafe { output.write(result) };
    STATUS_OK
}

/// Resizes and converts an image between supported output formats.
///
/// # Safety
///
/// Both path buffers must contain valid UTF-8 and remain readable for this call.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn toolpouch_image_transform(
    input_bytes: *const u8,
    input_length: usize,
    output_bytes: *const u8,
    output_length: usize,
    maximum_width: u32,
    maximum_height: u32,
    output_format: u32,
    quality: u8,
) -> i32 {
    let Some(input) = (unsafe { path_from_bytes(input_bytes, input_length) }) else {
        return STATUS_INVALID_ARGUMENT;
    };
    let Some(output) = (unsafe { path_from_bytes(output_bytes, output_length) }) else {
        return STATUS_INVALID_ARGUMENT;
    };
    let output_format = match output_format {
        1 => OutputFormat::Png,
        2 => OutputFormat::Jpeg,
        3 => OutputFormat::WebP,
        _ => return STATUS_INVALID_ARGUMENT,
    };
    match toolpouch_image::transform(
        &input,
        &output,
        TransformOptions {
            maximum_width,
            maximum_height,
            output_format,
            jpeg_quality: quality,
        },
    ) {
        Ok(()) => STATUS_OK,
        Err(TransformError::Io) => STATUS_IO_ERROR,
        Err(TransformError::InvalidImage) => STATUS_INVALID_IMAGE,
        Err(TransformError::EncodingFailed) => STATUS_ENCODING_FAILED,
    }
}

unsafe fn path_from_bytes(bytes: *const u8, length: usize) -> Option<PathBuf> {
    if bytes.is_null() || length == 0 {
        return None;
    }
    // SAFETY: The caller guarantees a readable buffer of `length` bytes.
    let bytes = unsafe { slice::from_raw_parts(bytes, length) };
    str::from_utf8(bytes).ok().map(PathBuf::from)
}

fn write_text(destination: &mut [u8; 128], value: Option<&str>) {
    let Some(value) = value else { return };
    let bytes = value.as_bytes();
    let length = bytes.len().min(destination.len() - 1);
    destination[..length].copy_from_slice(&bytes[..length]);
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

fn format_code(format: Format) -> u32 {
    match format {
        Format::Unknown => 0,
        Format::Png => 1,
        Format::Jpeg => 2,
        Format::Gif => 3,
        Format::WebP => 4,
        Format::Tiff => 5,
        Format::Bmp => 6,
        Format::Ico => 7,
        Format::Pnm => 8,
    }
}

fn color_model_code(color_model: ColorModel) -> u32 {
    match color_model {
        ColorModel::Unknown => 0,
        ColorModel::Grayscale => 1,
        ColorModel::GrayscaleAlpha => 2,
        ColorModel::Rgb => 3,
        ColorModel::Rgba => 4,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use image::{ImageBuffer, Rgba};
    use std::time::{SystemTime, UNIX_EPOCH};

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

    #[test]
    fn image_inspection_rejects_an_empty_path() {
        let mut output = ToolPouchImageInfo::default();
        let status = unsafe { toolpouch_image_inspect(std::ptr::null(), 0, &mut output) };

        assert_eq!(status, STATUS_INVALID_ARGUMENT);
    }

    #[test]
    fn image_inspection_maps_rust_results_to_the_c_abi() {
        let unique = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system clock should be valid")
            .as_nanos();
        let path = std::env::temp_dir().join(format!(
            "toolpouch-ffi-image-{}-{unique}.png",
            std::process::id()
        ));
        ImageBuffer::from_pixel(4, 5, Rgba([10_u8, 20, 30, 128]))
            .save(&path)
            .expect("test image should be written");
        let path_bytes = path.to_string_lossy();
        let mut output = ToolPouchImageInfo::default();

        let status =
            unsafe { toolpouch_image_inspect(path_bytes.as_ptr(), path_bytes.len(), &mut output) };
        let _ = std::fs::remove_file(path);

        assert_eq!(status, STATUS_OK);
        assert_eq!(output.width, 4);
        assert_eq!(output.height, 5);
        assert_eq!(output.format, 1);
        assert_eq!(output.color_model, 4);
        assert_eq!(output.channel_count, 4);
        assert_eq!(output.bits_per_channel, 8);
        assert_eq!(output.has_alpha, 1);
        assert!(output.file_size > 0);
    }

    #[test]
    fn metadata_reader_accepts_images_without_exif() {
        let unique = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system clock should be valid")
            .as_nanos();
        let path = std::env::temp_dir().join(format!("toolpouch-ffi-metadata-{unique}.png"));
        ImageBuffer::from_pixel(2, 2, Rgba([10_u8, 20, 30, 255]))
            .save(&path)
            .expect("test image should be written");
        let path_bytes = path.to_string_lossy();
        let mut output = ToolPouchImageMetadata::default();

        let status = unsafe {
            toolpouch_image_read_metadata(path_bytes.as_ptr(), path_bytes.len(), &mut output)
        };
        let _ = std::fs::remove_file(path);

        assert_eq!(status, STATUS_OK);
        assert_eq!(output.has_location, 0);
        assert_eq!(output.camera_make[0], 0);
    }
}
