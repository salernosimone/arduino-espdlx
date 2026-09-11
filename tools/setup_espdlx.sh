#!/bin/bash
# Regenerate the espdlx Arduino library from esp-dl source.
# Unified port: dl/ core + vision + audio + fbs_loader, flattened for
# the Arduino builder (only src/ itself is on the include path).
#
# Usage: ./setup_espdlx.sh [path/to/esp-dl-clone]
# Default source: /Users/simone/Dev/Arduino/projects/TF/esp-dl (v3.3.11)
#
# Layout (ESP32-S3 target):
#   src/              — flattened dl/ + vision + audio + fbs_loader
#   src/esp32s3/      — prebuilt fbs_loader/lib/esp32s3/libfbs_model.a
#                       (Arduino 'precompiled' layout)
#   src/espdlx.h      — unified entrypoint (preserved)
#   src/espdl_pix_cvt_config.h — Kconfig shim (recreated)
#
# Exclusions (ESP32-S3 only):
#   - isa/esp32p4 (P4 TIE)
#   - vision/image/dl_image_jpeg.cpp/hpp + vision/image/dl_image.hpp
#     (aggregator needing esp_new_jpeg, absent from Arduino core)
#   PPA files kept (driver/ppa.h exists; inert on S3).
#
# Does NOT touch library.properties / README / keywords.txt.
set -e
SRC=${1:-/Users/simone/Dev/Arduino/projects/TF/esp-dl}
LIBDIR="$(cd "$(dirname "$0")/.." && pwd)"
DST="$LIBDIR/src"
CORE="$SRC/esp-dl"

[ -d "$CORE/dl" ] || { echo "esp-dl core not found at $CORE"; exit 1; }

mkdir -p "$DST/esp32s3"

# Remember entrypoint if it exists (regenerate will preserve it)
TMP_HDR=""
if [ -f "$DST/espdlx.h" ]; then
  TMP_HDR=$(mktemp)
  cp "$DST/espdlx.h" "$TMP_HDR"
fi

# Clear generated flatten output (keep esp32s3 dir, keep tools/ and meta files one level up)
find "$DST" -maxdepth 1 -type f -delete
rm -f "$DST/esp32s3/libfbs_model.a"

echo "Copying dl/core..."
find "$CORE/dl" -type f \( -name "*.cpp" -o -name "*.c" -o -name "*.S" -o -name "*.h" -o -name "*.hpp" \) \
  | grep -v "isa/esp32p4" \
  | while read -r f; do cp "$f" "$DST/"; done

echo "Copying vision..."
find "$CORE/vision" -type f \( -name "*.cpp" -o -name "*.c" -o -name "*.S" -o -name "*.h" -o -name "*.hpp" \) \
  | grep -v "isa/esp32p4" \
  | grep -v -E "dl_image_jpeg\.(cpp|hpp)|vision/image/dl_image\.hpp" \
  | while read -r f; do cp "$f" "$DST/"; done

echo "Copying audio..."
find "$CORE/audio" -type f \( -name "*.cpp" -o -name "*.c" -o -name "*.S" -o -name "*.h" -o -name "*.hpp" \) \
  | while read -r f; do cp "$f" "$DST/"; done

echo "Copying fbs_loader..."
cp "$CORE"/fbs_loader/include/*.hpp "$DST/"
cp "$CORE"/fbs_loader/src/fbs_loader.cpp "$DST/"
cp "$CORE"/fbs_loader/lib/esp32s3/libfbs_model.a "$DST/esp32s3/"

# Restore or create unified entrypoint
if [ -n "$TMP_HDR" ]; then
  cp "$TMP_HDR" "$DST/espdlx.h"
  rm -f "$TMP_HDR"
else
  cat > "$DST/espdlx.h" <<'EOF'
#pragma once
/**
 * espdlx.h — unified entrypoint for the esp-dl Arduino port.
 */
#include "dl_tensor_base.hpp"
#include "dl_math.hpp"
#include "dl_model_base.hpp"
#include "dl_module_creator.hpp"
#include "dl_tool.hpp"
#include "dl_image_define.hpp"
#include "dl_image_process.hpp"
#include "dl_mfcc.hpp"
#include "dl_fbank.hpp"
#include "dl_spectrogram.hpp"
#include "dl_audio_wav.hpp"
#include "dl_detect_base.hpp"
#include "dl_cls_base.hpp"
EOF
fi

# PIX_CVT shim (recreate)
cat > "$DST/espdl_pix_cvt_config.h" <<'EOF'
#pragma once
// Arduino replacement for esp-dl Kconfig PIX_CVT_* options (all default y).
#define CONFIG_PIX_CVT_RGB565_TO_RGB565_SUPPORT 1
#define CONFIG_PIX_CVT_RGB565_TO_RGB888_SUPPORT 1
#define CONFIG_PIX_CVT_RGB565_TO_GRAY_SUPPORT 1
#define CONFIG_PIX_CVT_RGB565_TO_HSV_SUPPORT 1
#define CONFIG_PIX_CVT_RGB888_TO_RGB888_SUPPORT 1
#define CONFIG_PIX_CVT_RGB888_TO_RGB565_SUPPORT 1
#define CONFIG_PIX_CVT_RGB888_TO_GRAY_SUPPORT 1
#define CONFIG_PIX_CVT_RGB888_TO_HSV_SUPPORT 1
#define CONFIG_PIX_CVT_GRAY_TO_GRAY_SUPPORT 1
#define CONFIG_PIX_CVT_HSV_TO_HSV_MASK_SUPPORT 1
#define CONFIG_PIX_CVT_YUV_TO_RGB888_SUPPORT 1
#define CONFIG_PIX_CVT_YUV_TO_RGB565_SUPPORT 1
#define CONFIG_PIX_CVT_YUV_TO_GRAY_SUPPORT 1
#define CONFIG_PIX_CVT_YUV_TO_HSV_SUPPORT 1
#define CONFIG_PIX_CVT_YUV_TO_YUV_SUPPORT 1
EOF

for f in "$DST"/dl_image_pixel_cvt_dispatch_*.cpp; do
  [ -e "$f" ] || continue
  grep -q "espdl_pix_cvt_config.h" "$f" || sed -i '' '1i\
#include "espdl_pix_cvt_config.h"' "$f"
done
H="$DST/dl_image_pixel_cvt_dispatch.hpp"
if [ -f "$H" ]; then
  grep -q "espdl_pix_cvt_config.h" "$H" || sed -i '' 's|#pragma once|#pragma once\n#include "espdl_pix_cvt_config.h"|' "$H"
fi

echo "espdlx: $(ls "$DST" | wc -l) files in src/ (+ $(ls "$DST/esp32s3" | wc -l) prebuilt)"
echo "prebuilt: $(ls -lh "$DST/esp32s3/")"
echo "done. compile e.g.: arduino-cli compile --fqbn esp32:esp32:esp32s3 \"$LIBDIR/examples/SelfTest\""
