#!/bin/bash
set -e

echo "Generating flutter_rust_bridge bindings..."

flutter_rust_bridge_codegen generate \
  --rust-root spdfcore \
  --rust-input crate::ffi \
  --dart-output lib/bridge_generated.dart \
  --dart-format-line-length 80

echo "Done!"
