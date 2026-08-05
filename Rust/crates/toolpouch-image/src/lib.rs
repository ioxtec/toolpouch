use exif::{In, Reader as ExifReader, Tag, Value};
use image::codecs::jpeg::JpegEncoder;
use image::{ColorType, ImageDecoder, ImageFormat, ImageReader};
use std::fs::{self, File};
use std::io::BufReader;
use std::path::Path;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum Format {
    Png,
    Jpeg,
    Gif,
    WebP,
    Tiff,
    Bmp,
    Ico,
    Pnm,
    Unknown,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ColorModel {
    Grayscale,
    GrayscaleAlpha,
    Rgb,
    Rgba,
    Unknown,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ImageInfo {
    pub width: u32,
    pub height: u32,
    pub format: Format,
    pub color_model: ColorModel,
    pub channel_count: u8,
    pub bits_per_channel: u8,
    pub has_alpha: bool,
    pub file_size: u64,
}

#[derive(Debug)]
pub enum InspectError {
    Io,
    UnsupportedFormat,
    InvalidImage,
}

#[derive(Clone, Debug, Default, PartialEq)]
pub struct ImageMetadata {
    pub camera_make: Option<String>,
    pub camera_model: Option<String>,
    pub lens_model: Option<String>,
    pub captured_at: Option<String>,
    pub exposure_time: Option<String>,
    pub aperture: Option<String>,
    pub iso: Option<String>,
    pub focal_length: Option<String>,
    pub orientation: Option<String>,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum OutputFormat {
    Png,
    Jpeg,
    WebP,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct TransformOptions {
    pub maximum_width: u32,
    pub maximum_height: u32,
    pub output_format: OutputFormat,
    pub jpeg_quality: u8,
}

#[derive(Debug)]
pub enum TransformError {
    Io,
    InvalidImage,
    EncodingFailed,
}

pub fn inspect(path: &Path) -> Result<ImageInfo, InspectError> {
    let file_size = fs::metadata(path).map_err(|_| InspectError::Io)?.len();
    let reader = ImageReader::open(path)
        .map_err(|_| InspectError::Io)?
        .with_guessed_format()
        .map_err(|_| InspectError::InvalidImage)?;
    let format = reader
        .format()
        .map(Format::from)
        .ok_or(InspectError::UnsupportedFormat)?;
    let decoder = reader
        .into_decoder()
        .map_err(|_| InspectError::InvalidImage)?;
    let (width, height) = decoder.dimensions();
    let color_type = decoder.color_type();
    let (color_model, bits_per_channel) = color_details(color_type);

    Ok(ImageInfo {
        width,
        height,
        format,
        color_model,
        channel_count: color_type.channel_count(),
        bits_per_channel,
        has_alpha: color_type.has_alpha(),
        file_size,
    })
}

pub fn read_metadata(path: &Path) -> Result<ImageMetadata, InspectError> {
    let file = File::open(path).map_err(|_| InspectError::Io)?;
    let mut reader = BufReader::new(file);
    let exif = match ExifReader::new().read_from_container(&mut reader) {
        Ok(exif) => exif,
        Err(exif::Error::NotFound(_)) => return Ok(ImageMetadata::default()),
        Err(_) => return Err(InspectError::InvalidImage),
    };

    let text = |tag| {
        exif.get_field(tag, In::PRIMARY)
            .map(|field| field.display_value().with_unit(&exif).to_string())
            .filter(|value| !value.is_empty())
    };
    let latitude = gps_coordinate(&exif, Tag::GPSLatitude, Tag::GPSLatitudeRef);
    let longitude = gps_coordinate(&exif, Tag::GPSLongitude, Tag::GPSLongitudeRef);

    Ok(ImageMetadata {
        camera_make: text(Tag::Make),
        camera_model: text(Tag::Model),
        lens_model: text(Tag::LensModel),
        captured_at: text(Tag::DateTimeOriginal).or_else(|| text(Tag::DateTime)),
        exposure_time: text(Tag::ExposureTime),
        aperture: text(Tag::FNumber),
        iso: text(Tag::PhotographicSensitivity),
        focal_length: text(Tag::FocalLength),
        orientation: text(Tag::Orientation),
        latitude,
        longitude,
    })
}

pub fn transform(
    input: &Path,
    output: &Path,
    options: TransformOptions,
) -> Result<(), TransformError> {
    let image = ImageReader::open(input)
        .map_err(|_| TransformError::Io)?
        .with_guessed_format()
        .map_err(|_| TransformError::InvalidImage)?
        .decode()
        .map_err(|_| TransformError::InvalidImage)?;

    let transformed = if options.maximum_width > 0 && options.maximum_height > 0 {
        image.thumbnail(options.maximum_width, options.maximum_height)
    } else {
        image
    };

    match options.output_format {
        OutputFormat::Png => transformed
            .save_with_format(output, ImageFormat::Png)
            .map_err(|_| TransformError::EncodingFailed),
        OutputFormat::WebP => transformed
            .save_with_format(output, ImageFormat::WebP)
            .map_err(|_| TransformError::EncodingFailed),
        OutputFormat::Jpeg => {
            let file = File::create(output).map_err(|_| TransformError::Io)?;
            let mut encoder =
                JpegEncoder::new_with_quality(file, options.jpeg_quality.clamp(1, 100));
            encoder
                .encode_image(&transformed)
                .map_err(|_| TransformError::EncodingFailed)
        }
    }
}

fn gps_coordinate(exif: &exif::Exif, coordinate_tag: Tag, reference_tag: Tag) -> Option<f64> {
    let field = exif.get_field(coordinate_tag, In::PRIMARY)?;
    let values = match &field.value {
        Value::Rational(values) if values.len() >= 3 => values,
        _ => return None,
    };
    let reference = exif
        .get_field(reference_tag, In::PRIMARY)
        .and_then(|field| match &field.value {
            Value::Ascii(values) => values.first().and_then(|value| value.first()).copied(),
            _ => None,
        })?;
    let value = values[0].to_f64() + values[1].to_f64() / 60.0 + values[2].to_f64() / 3600.0;

    Some(if matches!(reference, b'S' | b'W') {
        -value
    } else {
        value
    })
}

fn color_details(color_type: ColorType) -> (ColorModel, u8) {
    match color_type {
        ColorType::L8 => (ColorModel::Grayscale, 8),
        ColorType::La8 => (ColorModel::GrayscaleAlpha, 8),
        ColorType::Rgb8 => (ColorModel::Rgb, 8),
        ColorType::Rgba8 => (ColorModel::Rgba, 8),
        ColorType::L16 => (ColorModel::Grayscale, 16),
        ColorType::La16 => (ColorModel::GrayscaleAlpha, 16),
        ColorType::Rgb16 => (ColorModel::Rgb, 16),
        ColorType::Rgba16 => (ColorModel::Rgba, 16),
        ColorType::Rgb32F => (ColorModel::Rgb, 32),
        ColorType::Rgba32F => (ColorModel::Rgba, 32),
        _ => (ColorModel::Unknown, 0),
    }
}

impl From<ImageFormat> for Format {
    fn from(value: ImageFormat) -> Self {
        match value {
            ImageFormat::Png => Self::Png,
            ImageFormat::Jpeg => Self::Jpeg,
            ImageFormat::Gif => Self::Gif,
            ImageFormat::WebP => Self::WebP,
            ImageFormat::Tiff => Self::Tiff,
            ImageFormat::Bmp => Self::Bmp,
            ImageFormat::Ico => Self::Ico,
            ImageFormat::Pnm => Self::Pnm,
            _ => Self::Unknown,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use image::{ImageBuffer, Rgba};
    use std::time::{SystemTime, UNIX_EPOCH};

    #[test]
    fn inspects_a_png_without_decoding_it_into_swift_memory() {
        let unique = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system clock should be valid")
            .as_nanos();
        let path = std::env::temp_dir().join(format!(
            "toolpouch-image-{}-{unique}.png",
            std::process::id()
        ));
        let image = ImageBuffer::from_pixel(3, 2, Rgba([10_u8, 20, 30, 128]));
        image.save(&path).expect("test image should be written");

        let info = inspect(&path).expect("test image should be inspected");
        let _ = fs::remove_file(path);

        assert_eq!(info.width, 3);
        assert_eq!(info.height, 2);
        assert_eq!(info.format, Format::Png);
        assert_eq!(info.color_model, ColorModel::Rgba);
        assert_eq!(info.channel_count, 4);
        assert_eq!(info.bits_per_channel, 8);
        assert!(info.has_alpha);
        assert!(info.file_size > 0);
    }

    #[test]
    fn reports_missing_files_as_io_errors() {
        let result = inspect(Path::new("/path/that/does/not/exist.png"));

        assert!(matches!(result, Err(InspectError::Io)));
    }

    #[test]
    fn resizes_and_converts_an_image() {
        let unique = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system clock should be valid")
            .as_nanos();
        let input = std::env::temp_dir().join(format!("toolpouch-input-{unique}.png"));
        let output = std::env::temp_dir().join(format!("toolpouch-output-{unique}.jpg"));
        let enlarged = std::env::temp_dir().join(format!("toolpouch-enlarged-{unique}.png"));
        ImageBuffer::from_pixel(400, 200, Rgba([10_u8, 20, 30, 255]))
            .save(&input)
            .expect("test image should be written");

        transform(
            &input,
            &output,
            TransformOptions {
                maximum_width: 100,
                maximum_height: 100,
                output_format: OutputFormat::Jpeg,
                jpeg_quality: 85,
            },
        )
        .expect("image should be transformed");
        let info = inspect(&output).expect("output should be readable");

        transform(
            &input,
            &enlarged,
            TransformOptions {
                maximum_width: 800,
                maximum_height: 400,
                output_format: OutputFormat::Png,
                jpeg_quality: 85,
            },
        )
        .expect("image should be enlarged");
        let enlarged_info = inspect(&enlarged).expect("enlarged output should be readable");
        let _ = fs::remove_file(input);
        let _ = fs::remove_file(output);
        let _ = fs::remove_file(enlarged);

        assert_eq!((info.width, info.height), (100, 50));
        assert_eq!(info.format, Format::Jpeg);
        assert_eq!((enlarged_info.width, enlarged_info.height), (800, 400));
    }
}
