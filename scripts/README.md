# Build Scripts

This directory contains platform-specific build scripts for the SmartPDF Rust library.

## Scripts

- **`build_ios.sh`** - Builds the Rust library for iOS (simulator and device)
- **`build_android.sh`** - Builds the Rust library for Android (all architectures)

## Usage

### Direct Script Usage
```bash
# Build for iOS
./scripts/build_ios.sh

# Build for Android  
./scripts/build_android.sh
```

### Using Makefile (Recommended)
```bash
# Build for iOS
make ios

# Build for Android
make android

# Build for both platforms
make all

# See all available commands
make help
```

## Requirements

- **Rust** with required targets installed
- **Flutter** with flutter_rust_bridge_codegen
- **cargo-ndk** for Android builds
- **Xcode** command line tools for iOS builds

Run `make setup` to install all required dependencies.

## Output Locations

### iOS
- Simulator dylib: `ios/Runner/Frameworks/libspdfcore.dylib`
- Device dylib: `ios/Runner/Frameworks/libspdfcore-device.dylib`
- Framework: `ios/Runner/Frameworks/spdfcore.framework/`

### Android
- Libraries: `android/app/src/main/jniLibs/*/libspdfcore.so`
- Architectures: arm64-v8a, armeabi-v7a, x86_64