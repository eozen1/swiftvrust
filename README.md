```markdown
# Swift vs Rust Benchmark Suite

This repository contains two small compute-heavy benchmarks to compare:
1. **Matrix multiplication** (600×600 double precision)
2. **2-layer neural-net backpropagation** (1024→512→10, 50 iterations)

Each benchmark has:
- **Swift ARM64** implementation
- **Rust ARM64** native implementation
- **Rust x86_64** implementation run under Rosetta

You can build and measure each variant individually, or use the provided script to automate everything.

---

## Repository Structure

```

.
├── README.md
├── matmul
│   ├── BenchMat.swift        # Swift matrix-multiply
│   ├── bench-rust            # Rust matrix-multiply project
│   └── bench-swift-mat       # Swift binary (after build)
└── neuralnet
├── BenchNN.swift         # Swift neural-net backprop
├── bench-rust            # Rust neural-net project
└── bench-swift-nn        # Swift binary (after build)

````

---

## Prerequisites

- **macOS Big Sur or later** on Apple Silicon
- [Homebrew](https://brew.sh/) (for installing tools)
- [rustup](https://rustup.rs/) & Rust toolchain
- [hyperfine](https://github.com/sharkdp/hyperfine) (for benchmarking)
- Xcode Command-Line Tools (for `swiftc`)

---

## Quickstart

1. **Clone the repo**  
   ```bash
   git clone https://github.com/yourusername/benchmark.git
   cd benchmark
````

2. **Install dependencies**

   ```bash
   brew install rustup-init hyperfine
   rustup-init -y
   source $HOME/.cargo/env
   rustup target add x86_64-apple-darwin
   ```

3. **Build & run a single benchmark**

   * **Matrix multiply (Swift):**

     ```bash
     cd matmul
     swiftc -O -Xfrontend -disable-availability-checking BenchMat.swift -o bench-swift-mat
     ./bench-swift-mat 600
     ```

   * **Matrix multiply (Rust ARM64):**

     ```bash
     cd matmul/bench-rust
     cargo build --release
     ../bench-swift-mat 600
     ```

   * **Neural-net backprop (Swift):**

     ```bash
     cd neuralnet
     swiftc -O -Xfrontend -disable-availability-checking BenchNN.swift -o bench-swift-nn
     ./bench-swift-nn 1024 512 10 50
     ```

   * **Neural-net backprop (Rust ARM64):**

     ```bash
     cd neuralnet/bench-rust
     cargo build --release
     ../bench-swift-nn 1024 512 10 50
     ```

4. **Run all benchmarks end-to-end**
   Use the provided script (make executable first):

   ```bash
   chmod +x run_benchmarks.sh
   ./run_benchmarks.sh
   ```

   This will:

   * Build both Swift and Rust variants (ARM64 & Rosetta)
   * Run `hyperfine` for matrix multiply and neural-net tests
   * Print mean ± σ timings and relative speedups

---

## Contributing

* Feel free to open issues or pull requests.
* To add another workload, follow the existing folder pattern:

  * Add a `.swift` file and compile with `swiftc`
  * Add/modify the Rust `src/main.rs` and `Cargo.toml`
  * Update `run_benchmarks.sh` with your new commands

---

## License

This project is licensed under the MIT License.

```
```
