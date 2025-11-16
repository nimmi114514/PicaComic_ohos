# Pica Comic (OHOS Fork)

[![flutter](https://img.shields.io/badge/flutter-3.35.1-blue)](https://flutter.dev/)
[![License](https://img.shields.io/github/license/Pacalini/PicaComic)](https://github.com/Pacalini/PicaComic/blob/master/LICENSE)
[![Download](https://img.shields.io/github/v/release/Pacalini/PicaComic)](https://github.com/Pacalini/PicaComic/releases)
[![stars](https://img.shields.io/github/stars/Pacalini/PicaComic)](https://github.com/Pacalini/PicaComic/stargazers)

A comic app with multiple sources built with flutter.

> **About this fork**
> This repository (`WJ-T/PicaComic_ohos`) is a HarmonyOS / OHOS adaptation of the upstream project [Pacalini/PicaComic](https://github.com/Pacalini/PicaComic).
> The original project retains Android / desktop support; this fork focuses on keeping the OHOS host project and build scripts up to date.

**Forked from [nyne](https://github.com/wgh136), provide extended support & fix, no guaranteed roadmap.**

## Download

<a href="https://github.com/Pacalini/PicaComic/releases">
<img src="https://user-images.githubusercontent.com/69304392/148696068-0cfea65d-b18f-4685-82b5-329a330b1c0d.png"
alt="Get it on GitHub" align="center" height="80" /></a>

<a href="https://github.com/Pacalini/PicaComic/blob/master/INSTALL.md#obtainium">
<img src="https://github.com/ImranR98/Obtainium/blob/main/assets/graphics/badge_obtainium.png"
alt="Get it on Obtainium" align="center" height="54" />
</a>

> 🛈 This fork does not publish official OHOS `.hap` releases yet — please follow the **HarmonyOS / OHOS** section below to build locally.

An [AUR package](https://aur.archlinux.org/packages/pica-comic-bin) is packed by [Lilinzta](https://github.com/Lilinzta):

```shell
paru -S pica-comic-bin
```

## Build

1. Clone the repository

```shell
git clone https://github.com/WJ-T/PicaComic_ohos
```

2. Install flutter: https://docs.flutter.dev/get-started/install
3. Build Application: https://docs.flutter.dev/deployment

## HarmonyOS / OHOS (experimental)

An OpenHarmony host project now lives under `ohos/`. To produce a `.hap` package:

1. Install the OpenHarmony or HarmonyOS SDK and set `OHOS_SDK_HOME` (or run `flutter config --ohos-sdk <path>`).
2. Enable the Flutter OHOS feature and fetch artifacts：

   ```shell
   flutter config --enable-ohos
   flutter precache --ohos
   ./tool/prepare_ohos_har.sh
   ```
3. Build the QuickJS FFI library for HarmonyOS (needed for the in-app JS engine):

   ```shell
   ./tool/build_quickjs_ohos.sh
   ```

   The script compiles `libflutter_qjs_plugin.so` for `arm64-v8a` and `x86_64` with the DevEco / HarmonyOS toolchain. Re-run it whenever you update `flutter_qjs/cxx`.
4. Build the Hap from the repo root (arm64 by default):

   ```shell
   flutter build hap --target-platform=ohos-arm64
   ```

   The output appears under `build/ohos/outputs/`.
5. Build a **release** hap (make sure your `flutter.har` comes from the release engine; debug engines expect JIT artifacts and will crash on AOT packages):

   ```shell
   rm -f ohos/har/flutter.har
   ./tool/prepare_ohos_har.sh ohos-arm64-release
   cd ohos
   ohpm clean && ohpm install --all
   cd ..
   HOS_SDK_HOME=/path/to/HarmonyOS_SDK \
     flutter build hap --release --target-platform=ohos-arm64
   ```

   - `HOS_SDK_HOME` must point to a HarmonyOS SDK that contains both `hmscore` and `openharmony`; the OpenHarmony SDK bundled with DevEco Studio alone is not enough.
   - After the build finishes, run `unzip -p ohos/entry/build/default/outputs/default/entry-default-signed.hap module.json | grep buildMode` to confirm it is `release`.
6. If you prefer to keep building/running directly inside DevEco Studio/Hvigor instead of `flutter build hap`, run before each build:

   ```shell
   ./tool/sync_ohos_flutter_assets.sh [debug|profile|release]
   ```
7. Optionally open the `ohos` folder in DevEco Studio 5.0+ to fine-tune signing or launch on a device/emulator.

The `ohos/har` directory is ignored by git—`flutter build hap` copies the required `flutter.har` there automatically. Most pure-Dart plugins work out of the box; native functionality still requires individual OHOS implementations.

## Introduction

### Built-in Comic Source

Currently, Pica Comic has 5 built-in comic sources:

- picacg
- e-hentai/exhentai
- jmcomic
- hitomi
- htcomic
- nhentai

### Features

- Browse manga
- Online reading
- Download manga
- Manage local favorites and network favorites
- Data sync(using webdav)
- Reading history

### History

This project initially started as an unofficial app for picacg
and later evolved into an app that supports multiple comic sources.

## Thanks

### Projects

[![Readme Card](https://github-readme-stats.vercel.app/api/pin/?username=tonquer&repo=JMComic-qt)](https://github.com/tonquer/JMComic-qt)

The image restructuring algorithm used to display jm images is from this project.

### Tags Translation

[![Readme Card](https://github-readme-stats.vercel.app/api/pin/?username=EhTagTranslation&repo=Database)](https://github.com/EhTagTranslation/Database)

The Chinese translation of the manga tags is from this project.
