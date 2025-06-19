#!/usr/bin/env bash
set -e

# --- Dependency installation ---
# Install Homebrew if missing
if ! command -v brew &> /dev/null; then
  echo "Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install rustup if missing
if ! command -v rustup &> /dev/null; then
  echo "rustup not found. Installing rustup via Homebrew..."
  brew install rustup-init
  rustup-init -y
  source "$HOME/.cargo/env"
fi

# Add x86_64 target for Rosetta builds
echo "Adding x86_64-apple-darwin Rust target..."
rustup target add x86_64-apple-darwin || true

# Install hyperfine if missing
if ! command -v hyperfine &> /dev/null; then
  echo "hyperfine not found. Installing hyperfine..."
  brew install hyperfine
fi

# --- Matrix multiply benchmark ---
echo "\n=== Matrix Multiply Benchmark ==="
pushd matmul > /dev/null

# Swift build
echo "Building Swift matrix multiply..."
swiftc -O -Xfrontend -disable-availability-checking BenchMat.swift -o bench-swift-mat

# Rust builds
echo "Building Rust matrix multiply (ARM64)..."
pushd bench-rust > /dev/null
cargo build --release

echo "Building Rust matrix multiply (Rosetta x86_64)..."
cargo build --release --target x86_64-apple-darwin
popd > /dev/null

# Run hyperfine
echo "Running matrix multiply benchmark..."
hyperfine --warmup 5 --prepare 'sync' --runs 20 \
  './bench-swift-mat 600' \
  'arch -x86_64 ./bench-rust/target/x86_64-apple-darwin/release/bench-rust 600' \
  './bench-rust/target/release/bench-rust 600'

popd > /dev/null

# --- Neural net backprop benchmark ---
echo "\n=== Neural Net Backprop Benchmark ==="
pushd neuralnet > /dev/null

# Swift build
echo "Building Swift neural net benchmark..."
swiftc -O -Xfrontend -disable-availability-checking BenchNN.swift -o bench-swift-nn

# Rust builds
echo "Building Rust neural net benchmark (ARM64)..."
pushd bench-rust > /dev/null
cargo build --release

echo "Building Rust neural net benchmark (Rosetta x86_64)..."
cargo build --release --target x86_64-apple-darwin
popd > /dev/null

# Run hyperfine
echo "Running neural net benchmark..."
hyperfine --warmup 5 --prepare 'sync' --runs 20 \
  './bench-swift-nn 1024 512 10 50' \
  'arch -x86_64 ./bench-rust/target/x86_64-apple-darwin/release/bench-rust 1024 512 10 50' \
  './bench-rust/target/release/bench-rust 1024 512 10 50'

popd > /dev/null

echo "\nAll benchmarks completed."
