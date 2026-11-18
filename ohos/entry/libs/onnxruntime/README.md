# ONNX Runtime for OHOS ARM64

`../arm64-v8a/libonnxruntime.so` is ONNX Runtime 1.27.0, built for OHOS
by the `csukuangfj/onnxruntime-libs` project. The translation worker uses
its C API through Dart FFI, without a Flutter method-channel plugin.

- Build workflow: https://github.com/csukuangfj/onnxruntime-libs/blob/master/.github/workflows/harmony-os-shared.yaml
- Archive: https://huggingface.co/csukuangfj2/onnxruntime-libs/resolve/main/onnxruntime-ohos-arm64-v8a-1.27.0.zip
- Archive SHA-256: `6891743ed53e370f643a6ae55d7a56dd9f3b22151ec195202c09ee4234466b7c`
- Library SHA-256 before packaging: `4888f13dc420d94e50b028af26b42b4323bd82ea07d2a36a04945397188cc72d`

To reproduce, verify the archive hash and copy its `lib/libonnxruntime.so`
to `ohos/entry/libs/arm64-v8a/`. Keep the archive's `LICENSE` and
`ThirdPartyNotices.txt` in `ohos/entry/src/main/resources/rawfile/onnxruntime/`
so they accompany the binary in the HAP. Hvigor packages and strips the
library together with the other OHOS native libraries.
