#!/usr/bin/env bash
# 构建小零定制版 DiPlay（com.shihab.diplay.xl）的正式签名 APK。
# 需要：ANDROID_HOME（Android SDK）、DIPLAY_AUTH_ASSETS_DIR（offline-mfi 认证素材目录，见 docs/BUILD.md）、
# XL_KEYS（小零仓库旁边的 code/keys，里面的 diplay-xl.env 给出签名用的四个变量）。
# 产物：mobile/build/outputs/apk/release/mobile-release.apk，最后打印包名、版本和 sha256。
set -euo pipefail
cd "$(dirname "$0")/.."
: "${ANDROID_HOME:?需要 ANDROID_HOME}"
: "${DIPLAY_AUTH_ASSETS_DIR:?需要 DIPLAY_AUTH_ASSETS_DIR（offline-mfi 认证素材）}"
KEYS=${XL_KEYS:?需要 XL_KEYS（code/keys 目录）}
set -a; . "$KEYS/diplay-xl.env"; set +a
for f in identity.pk8 certificate.p7b; do
  [ -s "$DIPLAY_AUTH_ASSETS_DIR/offline-mfi/$f" ] || { echo "缺认证素材 $f" >&2; exit 1; }
done
./gradlew -q :mobile:assembleRelease
APK=mobile/build/outputs/apk/release/mobile-release.apk
AAPT=$(ls -d "$ANDROID_HOME"/build-tools/*/ | sort -V | tail -1)aapt
"$AAPT" dump badging "$APK" | sed -n 1p
for f in identity.pk8 certificate.p7b; do
  unzip -p "$APK" "assets/offline-mfi/$f" | cmp -s - "$DIPLAY_AUTH_ASSETS_DIR/offline-mfi/$f" || { echo "APK 里的 $f 和素材不一致" >&2; exit 1; }
done
sha256sum "$APK"
