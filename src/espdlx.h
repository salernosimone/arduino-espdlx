#pragma once
/**
 * espdlx.h — unified entrypoint for the esp-dl Arduino port.
 *
 * This header pulls the most-used public APIs from the three esp-dl
 * sub-modules (dl core, vision, audio) that are now unified in the
 * espdlx Arduino library. You can include this single header and get
 * TensorBase/Model + image + audio helpers, or include individual
 * headers directly (e.g. "dl_image_process.hpp", "dl_mfcc.hpp").
 *
 * Flattened for ESP32-S3 (TIE728). Ships S3 prebuilt fbs_model lib at
 * src/esp32s3/libfbs_model.a (precompiled=true, ldflags=-lfbs_model).
 */

#include "dl_tensor_base.hpp"
#include "dl_math.hpp"
#include "dl_model_base.hpp"
#include "dl_module_creator.hpp"
#include "dl_tool.hpp"

// Vision — image preprocessing / colour / transform
#include "dl_image_define.hpp"
#include "dl_image_process.hpp"

// Audio — MFCC / Fbank / spectrogram / wav
#include "dl_mfcc.hpp"
#include "dl_fbank.hpp"
#include "dl_spectrogram.hpp"
#include "dl_audio_wav.hpp"

// Optional but handy — keep them reachable without extra includes
#include "dl_detect_base.hpp"
#include "dl_cls_base.hpp"
