use std::time::Instant;

fn main() {
    // 1) Read N
    let mut args = std::env::args();
    let _ = args.next(); // skip exe name
    let n: usize = match args.next().and_then(|s| s.parse().ok()) {
        Some(val) if val > 0 => val,
        _ => {
            eprintln!("Usage: bench-rust-mat <positive-integer>");
            std::process::exit(1);
        }
    };

    // 2) Tiny LCG PRNG
    let mut seed: u64 = 0xC0FFEE123456789u64;
    let mut next_rand = || {
        // constants from PCG-ish
        seed = seed
            .wrapping_mul(6364136223846793005)
            .wrapping_add(1);
        // shift down to [0,1)
        ((seed >> 11) as f64) / ((1u64 << 53) as f64)
    };

    // 3) Allocate & fill A, B
    let mut A = Vec::with_capacity(n * n);
    let mut B = Vec::with_capacity(n * n);
    for _ in 0..n * n {
        let v = next_rand();
        A.push(v);
        B.push(v);
    }

    // 4) Prepare C
    let mut C = vec![0.0; n * n];

    // 5) Time naive matrix multiply
    let start = Instant::now();
    for i in 0..n {
        let row = i * n;
        for j in 0..n {
            let mut sum = 0.0;
            for k in 0..n {
                sum += A[row + k] * B[k * n + j];
            }
            C[row + j] = sum;
        }
    }
    let elapsed_ms = start.elapsed().as_secs_f64() * 1_000.0;

    // 6) Report
    println!("N={}  time={:.3} ms", n, elapsed_ms);
}
