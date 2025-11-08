#!/bin/bash
set -e

echo "Generating flutter_rust_bridge bindings for iOS..."

# Generate FFI bindings
flutter_rust_bridge_codegen generate \
  --rust-root spdfcore \
  --rust-input crate::ffi \
  --dart-output lib/bridge_generated.dart \
  --dart-format-line-length 80

echo "Building Rust library for iOS..."
cd spdfcore

# Build for iOS targets
echo "Building for iOS (arm64 device)..."
cargo build --release --target aarch64-apple-ios

echo "Building for iOS (x86_64 simulator)..."
cargo build --release --target x86_64-apple-ios

echo "Building for iOS (arm64 simulator)..."
cargo build --release --target aarch64-apple-ios-sim

# Copy iOS libraries to correct locations
echo "Setting up iOS libraries..."
mkdir -p ../ios/Runner/Frameworks

# Create universal binary for iOS simulator  
echo "Creating iOS simulator universal binary..."
lipo -create \
  target/x86_64-apple-ios/release/libspdfcore.dylib \
  target/aarch64-apple-ios-sim/release/libspdfcore.dylib \
  -output ../ios/Runner/Frameworks/libspdfcore.dylib

# For device builds, copy the arm64 binary
echo "Copying iOS device binary..."
cp target/aarch64-apple-ios/release/libspdfcore.dylib ../ios/Runner/Frameworks/libspdfcore-device.dylib

# Also create the framework structure that flutter_rust_bridge expects
echo "Creating iOS framework structure..."
mkdir -p ../ios/Runner/Frameworks/spdfcore.framework
cp ../ios/Runner/Frameworks/libspdfcore.dylib ../ios/Runner/Frameworks/spdfcore.framework/spdfcore

# Create Info.plist for the framework
cat > ../ios/Runner/Frameworks/spdfcore.framework/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.example.spdfcore</string>
    <key>CFBundleName</key>
    <string>spdfcore</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleExecutable</key>
    <string>spdfcore</string>
</dict>
</plist>
EOF

cd ..
echo "Done! iOS libraries created:"
echo "  - Simulator: ios/Runner/Frameworks/libspdfcore.dylib"
echo "  - Device: ios/Runner/Frameworks/libspdfcore-device.dylib"
echo "  - Framework: ios/Runner/Frameworks/spdfcore.framework/spdfcore"