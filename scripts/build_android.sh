#!/bin/bash
set -e

echo "Generating flutter_rust_bridge bindings for Android..."

# Generate FFI bindings
flutter_rust_bridge_codegen generate \
  --rust-root spdfcore \
  --rust-input crate::ffi \
  --dart-output lib/bridge_generated.dart \
  --dart-format-line-length 80

echo "Building Rust library for Android..."
cd spdfcore

# Build for Android targets
cargo ndk \
    -t arm64-v8a \
    -t armeabi-v7a \
    -t x86_64 \
    -o ../android/app/src/main/jniLibs \
    build --release

cd ..
echo "Done! Android libraries created:"
echo "  - arm64-v8a: android/app/src/main/jniLibs/arm64-v8a/libspdfcore.so"
echo "  - armeabi-v7a: android/app/src/main/jniLibs/armeabi-v7a/libspdfcore.so"
echo "  - x86_64: android/app/src/main/jniLibs/x86_64/libspdfcore.so"