#ifndef TOOLPOUCH_ENGINE_H
#define TOOLPOUCH_ENGINE_H

#include <stddef.h>
#include <stdint.h>

#define TOOLPOUCH_ENGINE_STATUS_OK 0
#define TOOLPOUCH_ENGINE_STATUS_INVALID_ARGUMENT 1
#define TOOLPOUCH_ENGINE_STATUS_IO_ERROR 2
#define TOOLPOUCH_ENGINE_STATUS_UNSUPPORTED_FORMAT 3
#define TOOLPOUCH_ENGINE_STATUS_INVALID_IMAGE 4
#define TOOLPOUCH_ENGINE_STATUS_ENCODING_FAILED 5

typedef struct ToolPouchImageInfo {
    uint32_t width;
    uint32_t height;
    uint32_t format;
    uint32_t color_model;
    uint8_t channel_count;
    uint8_t bits_per_channel;
    uint8_t has_alpha;
    uint8_t reserved;
    uint64_t file_size;
} ToolPouchImageInfo;

typedef struct ToolPouchImageMetadata {
    uint8_t camera_make[128];
    uint8_t camera_model[128];
    uint8_t lens_model[128];
    uint8_t captured_at[128];
    uint8_t exposure_time[128];
    uint8_t aperture[128];
    uint8_t iso[128];
    uint8_t focal_length[128];
    uint8_t orientation[128];
    double latitude;
    double longitude;
    uint8_t has_location;
    uint8_t reserved[7];
} ToolPouchImageMetadata;

uint32_t toolpouch_engine_api_version(void);

int32_t toolpouch_engine_crc32(
    const uint8_t *bytes,
    size_t length,
    uint32_t *output
);

int32_t toolpouch_image_inspect(
    const uint8_t *path_bytes,
    size_t path_length,
    ToolPouchImageInfo *output
);

int32_t toolpouch_image_read_metadata(
    const uint8_t *path_bytes,
    size_t path_length,
    ToolPouchImageMetadata *output
);

int32_t toolpouch_image_transform(
    const uint8_t *input_bytes,
    size_t input_length,
    const uint8_t *output_bytes,
    size_t output_length,
    uint32_t maximum_width,
    uint32_t maximum_height,
    uint32_t output_format,
    uint8_t quality
);

#endif
