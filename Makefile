# SmartPDF Build System
# This Makefile provides convenient commands for building the Rust library for different platforms

.PHONY: help clean setup ios android all flutter-deps rust-check

# Default target
help:
	@echo "SmartPDF Build Commands:"
	@echo ""
	@echo "  make setup         - Install required tools and dependencies"
	@echo "  make ios           - Build Rust library for iOS (simulator + device)"
	@echo "  make android       - Build Rust library for Android (all architectures)"
	@echo "  make all           - Build for both iOS and Android"
	@echo "  make clean         - Clean all build artifacts"
	@echo "  make flutter-deps  - Get Flutter dependencies"
	@echo "  make rust-check    - Check Rust code quality"
	@echo ""
	@echo "Flutter Commands:"
	@echo "  make run-ios       - Build and run iOS app"
	@echo "  make run-android   - Build and run Android app"
	@echo "  make test          - Run Flutter tests"
	@echo ""

# Setup required tools and dependencies
setup:
	@echo "🔧 Setting up development environment..."
	@echo "Checking Flutter installation..."
	@flutter --version
	@echo "Checking Rust installation..."
	@rustc --version
	@echo "Installing required Rust targets..."
	@rustup target add aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim
	@rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android
	@echo "Installing cargo-ndk..."
	@cargo install cargo-ndk || true
	@echo "Installing flutter_rust_bridge_codegen..."
	@cargo install flutter_rust_bridge_codegen || true
	@echo "✅ Setup complete!"

# Build Rust library for iOS
ios:
	@echo "🍎 Building for iOS..."
	@./scripts/build_ios.sh
	@cd ios && ruby setup_framework.rb
	@echo "✅ iOS build complete!"

# Build Rust library for Android  
android:
	@echo "🤖 Building for Android..."
	@./scripts/build_android.sh
	@echo "✅ Android build complete!"

# Build for all platforms
all: android ios
	@echo "✅ All platforms built successfully!"

# Clean all build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@flutter clean
	@cd spdfcore && cargo clean
	@rm -rf ios/Runner/Frameworks/lib*.dylib
	@rm -rf ios/Runner/Frameworks/spdfcore.framework
	@rm -rf android/app/src/main/jniLibs
	@echo "✅ Clean complete!"

# Get Flutter dependencies
flutter-deps:
	@echo "📦 Getting Flutter dependencies..."
	@flutter pub get
	@echo "✅ Flutter dependencies updated!"

# Check Rust code quality
rust-check:
	@echo "🔍 Checking Rust code..."
	@cd spdfcore && cargo check
	@cd spdfcore && cargo clippy -- -D warnings
	@cd spdfcore && cargo fmt --check || (echo "❌ Code not formatted. Run 'cd spdfcore && cargo fmt'" && exit 1)
	@echo "✅ Rust code quality check passed!"

# Build and run iOS app
run-ios: ios
	@echo "🍎 Running iOS app..."
	@flutter run -d ios

# Build and run Android app  
run-android: android
	@echo "🤖 Running Android app..."
	@flutter run -d android

# Build iOS release
build-ios-release: ios
	@echo "🍎 Building iOS release..."
	@flutter build ios --release

# Build Android release
build-android-release: android  
	@echo "🤖 Building Android release..."
	@flutter build appbundle --release

# Run Flutter tests
test:
	@echo "🧪 Running Flutter tests..."
	@flutter test

# Format Rust code
rust-format:
	@echo "🎨 Formatting Rust code..."
	@cd spdfcore && cargo fmt
	@echo "✅ Rust code formatted!"

# Update Rust dependencies
rust-update:
	@echo "📦 Updating Rust dependencies..."
	@cd spdfcore && cargo update
	@echo "✅ Rust dependencies updated!"

# Development shortcuts
dev-ios: flutter-deps ios run-ios
dev-android: flutter-deps android run-android

# CI/CD targets
ci-check: rust-check test
	@echo "✅ CI checks passed!"

ci-build: flutter-deps all build-ios-release build-android-release
	@echo "✅ CI build complete!"