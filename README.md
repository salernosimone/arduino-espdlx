# espdlx — esp-dl Arduino library (unified)

Arduino port of [esp-dl](https://github.com/espressif/esp-dl) **v3.3.11** for **ESP32-S3** as a precompiled library.

## Install

Search `espdlx` in the Arduino Library Manager.

## Usage

```cpp
#include <espdlx.h>

void setup() {
  Serial.begin(115200);
  float data[4] = {1,2,3,4};
  dl::TensorBase t({4}, data, 0, dl::DATA_TYPE_FLOAT, true);
  dl::math::softmax((float*)t.data, 4);
}
```

Individual headers remain includable directly, e.g. `dl_image_process.hpp`, `dl_mfcc.hpp`.

## Examples

- `examples/SelfTest` — self-test covering core (TensorBase+softmax), vision (ImageTransformer), and audio (MFCC) via `espdlx.h` (compiles on ESP32-S3).

## License

MIT (esp-dl upstream). See `esp-dl/esp-dl/LICENSE`.
