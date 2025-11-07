#!/bin/bash
set -e

echo "Generating flutter_rust_bridge bindings..."
flutter_rust_bridge_codegen generate \
  --rust-root spdfcore \
  --rust-input crate::ffi \
  --dart-output lib/bridge_generated.dart \
  --dart-format-line-length 80

echo "Building Rust library for Android..."
cd spdfcore

cargo ndk \
    -t arm64-v8a \
    -t armeabi-v7a \
    -t x86_64 \
    -o ../android/app/src/main/jniLibs \
    build --release

cd ..
echo "Done!"
