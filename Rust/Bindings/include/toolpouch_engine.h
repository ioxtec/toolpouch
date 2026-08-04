#ifndef TOOLPOUCH_ENGINE_H
#define TOOLPOUCH_ENGINE_H

#include <stddef.h>
#include <stdint.h>

#define TOOLPOUCH_ENGINE_STATUS_OK 0
#define TOOLPOUCH_ENGINE_STATUS_INVALID_ARGUMENT 1

uint32_t toolpouch_engine_api_version(void);

int32_t toolpouch_engine_crc32(
    const uint8_t *bytes,
    size_t length,
    uint32_t *output
);

#endif
