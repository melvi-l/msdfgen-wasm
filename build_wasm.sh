#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_ROOT="${SRC_ROOT:-$SCRIPT_DIR}"   

BUILD_DIR="${BUILD_DIR:-$SRC_ROOT/build_wasm}"
DIST_DIR="${DIST_DIR:-$SRC_ROOT/dist}"
SHIM_SRC="${SHIM_SRC:-$SRC_ROOT/wasm/shim.cpp}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dist)       DIST_DIR="$(realpath "$2")"; shift 2 ;;
    --build-dir)  BUILD_DIR="$(realpath "$2")"; shift 2 ;;
    --shim)       SHIM_SRC="$(realpath "$2")"; shift 2 ;;

    --src-root)   SRC_ROOT="$(realpath "$2")"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

command -v emcmake >/dev/null || { echo "Emscripten not found. source ~/emsdk/emsdk_env.sh"; exit 1; }
command -v em++    >/dev/null || { echo "Emscripten not found. source ~/emsdk/emsdk_env.sh"; exit 1; }

[[ -f "$SRC_ROOT/msdfgen.h" && -d "$SRC_ROOT/core" ]] || {
  echo "ERROR: SRC_ROOT is wrong. Expect msdfgen.h + core/ in $SRC_ROOT"; exit 1; }

[[ -f "$SHIM_SRC" ]] || { echo "Missing shim: $SHIM_SRC"; exit 1; }

echo "==> Configure (CMake + Emscripten)"
emcmake cmake -S "$SRC_ROOT" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DMSDFGEN_CORE_ONLY=ON \
  -DMSDFGEN_BUILD_STANDALONE=OFF \
  -DMSDFGEN_USE_VCPKG=OFF

echo "==> Build msdfgen-core"
cmake --build "$BUILD_DIR" --config Release --target msdfgen-core

echo "==> Link to WebAssembly"
mkdir -p "$DIST_DIR"
em++ -O3 -std=c++17 \
  -DMSDFGEN_PUBLIC= \
  -I"$SRC_ROOT" -I"$BUILD_DIR/include" \
  "$SHIM_SRC" "$BUILD_DIR/libmsdfgen-core.a" \
  -s MODULARIZE=1 \
  -s EXPORT_ES6=1 \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s "EXPORTED_RUNTIME_METHODS=['cwrap','ccall']" \
  -s "EXPORTED_FUNCTIONS=['_msdf_shape_new','_msdf_shape_free','_msdf_shape_add_contour','_msdf_contour_add_line','_msdf_contour_add_quadratic','_msdf_contour_add_cubic','_msdf_edge_color','_msdf_generate_msdf']" \
  -o "$DIST_DIR/msdfgen_core.js"

echo "==> Done."
echo "Output:"
echo "  $DIST_DIR/msdfgen_core.js"
echo "  $DIST_DIR/msdfgen_core.wasm"

