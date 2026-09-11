#include <Arduino.h>
#include <espdlx.h>
// espdlx SelfTest: exercises core + vision + audio via espdlx.h.
// Each domain is isolated in its own function for clarity.

static uint8_t s_src[32 * 32 * 3];
static uint8_t s_dst[16 * 16];

void testCore() {
  float data[4] = {1.0f, 2.0f, 3.0f, 4.0f};
  dl::TensorBase t({4}, data, 0, dl::DATA_TYPE_FLOAT, true);
  float *f = (float *)t.data;
  dl::math::softmax(f, 4);
  Serial.printf("[core] softmax: %.4f %.4f %.4f %.4f (sum=%.4f) %s\n",
                f[0], f[1], f[2], f[3], f[0] + f[1] + f[2] + f[3],
                fabsf(f[0] + f[1] + f[2] + f[3] - 1.0f) < 1e-3 ? "OK" : "FAIL");
}

void testVision() {
  for (int y = 0; y < 32; y++) {
    for (int x = 0; x < 32; x++) {
      s_src[(y * 32 + x) * 3 + 0] = (uint8_t)(x * 8);
      s_src[(y * 32 + x) * 3 + 1] = (uint8_t)(y * 8);
      s_src[(y * 32 + x) * 3 + 2] = 128;
    }
  }
  dl::image::img_t s{(void *)s_src, 32, 32, dl::image::DL_IMAGE_PIX_TYPE_RGB888};
  dl::image::img_t d{(void *)s_dst, 16, 16, dl::image::DL_IMAGE_PIX_TYPE_GRAY};
  dl::image::ImageTransformer tr;
  esp_err_t r = tr.set_src_img(s).set_dst_img(d).transform();
  Serial.printf("[vision] rgb888 32x32 -> gray 16x16: %s corners %d %d %d %d\n",
                r == ESP_OK ? "OK" : "FAIL", s_dst[0], s_dst[15],
                s_dst[15 * 16], s_dst[15 * 16 + 15]);
}

void testAudio() {
  static int16_t pcm[400];
  static float feat[13];
  for (int i = 0; i < 400; i++) {
    pcm[i] = (int16_t)(10000.0f * sinf(2.0f * 3.14159265f * 440.0f * i / 16000.0f));
  }
  dl::audio::SpeechFeatureConfig cfg;
  dl::audio::MFCC mfcc(cfg);
  esp_err_t r = mfcc.process_frame(pcm, 400, feat);
  Serial.printf("[audio] mfcc.process_frame(): %s ceps[0]=%.2f\n",
                r == ESP_OK ? "OK" : "FAIL", feat[0]);
}

void setup() {
  Serial.begin(115200);
  delay(500);
}

void loop() {
  Serial.println("espdlx SelfTest");

  testCore();
  testVision();
  testAudio();

  Serial.println("espdlx SelfTest: done");
  delay(5000);
}
