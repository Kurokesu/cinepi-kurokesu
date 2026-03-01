#!/usr/bin/bash
# CinePI RAW backend launcher
# Starts cinepi-raw with shared memory context and MJPEG preview

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Default tuning file (override with TUNING_FILE env var)
TUNING_FILE="${TUNING_FILE:-$REPO_DIR/tuning/imx283.json}"

# Default sensor mode (override with SENSOR_MODE env var)
# IMX283: 2784:1828:12:U (full readout, 12-bit)
SENSOR_MODE="${SENSOR_MODE:-2784:1828:12:U}"

# Preview resolution (matches sensor's native ~3:2 aspect ratio to avoid distortion)
LORES_WIDTH="${LORES_WIDTH:-960}"
LORES_HEIGHT="${LORES_HEIGHT:-630}"

BINARY="$REPO_DIR/cinepi-raw/build/cinepi/cinepi-raw"
if [ ! -x "$BINARY" ]; then
    echo "ERROR: cinepi-raw not built. Run: cd $REPO_DIR/cinepi-raw && meson setup build --buildtype=release && ninja -C build" >&2
    exit 1
fi

export CINEPI_SKIP_SOUND=1
export CINEPI_SKIP_REDIS_SUBSCRIBER=1

# Suppress per-frame libcamera warnings (no lux calibration data)
export LIBCAMERA_LOG_LEVELS="${LIBCAMERA_LOG_LEVELS:-RPiAgc:ERROR,RPiCcm:ERROR}"

exec "$BINARY" \
    --post-process-file "$REPO_DIR/config/post-processing.json" \
    --tuning-file "$TUNING_FILE" \
    -n \
    --mode "$SENSOR_MODE" \
    --width "$LORES_WIDTH" \
    --height "$LORES_HEIGHT" \
    --lores-width "$LORES_WIDTH" \
    --lores-height "$LORES_HEIGHT"
