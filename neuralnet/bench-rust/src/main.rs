use std::time::Instant;
use std::env;

fn main() {
    // 1) Parse arguments
    let args: Vec<usize> = env::args().skip(1)
        .map(|s| s.parse().unwrap_or(0))
        .collect();
    if args.len() != 4 || args.iter().any(|&x| x == 0) {
        eprintln!(
            "Usage: bench-rust-nn <inputSize> <hiddenSize> <outputSize> <iterations>"
        );
        std::process::exit(1);
    }
    let (input_size, hidden_size, output_size, iterations) =
        (args[0], args[1], args[2], args[3]);

    // 2) Tiny LCG PRNG for [-1,1)
    let mut seed: u64 = 0xDEADBEEF12345678;
    let mut next_rand = || {
        seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1);
        (((seed >> 11) as f64) / ((1u64 << 53) as f64)) * 2.0 - 1.0
    };

    // 3) Allocate & initialize weights, biases, inputs, targets
    let mut w1 = Vec::with_capacity(input_size * hidden_size);
    for _ in 0..input_size * hidden_size {
        w1.push(next_rand());
    }
    let mut b1 = vec![0.0; hidden_size];

    let mut w2 = Vec::with_capacity(hidden_size * output_size);
    for _ in 0..hidden_size * output_size {
        w2.push(next_rand());
    }
    let mut b2 = vec![0.0; output_size];

    let x = (0..input_size).map(|_| next_rand()).collect::<Vec<_>>();
    let y_true = (0..output_size).map(|_| next_rand()).collect::<Vec<_>>();

    // 4) Working buffers
    let mut hidden = vec![0.0; hidden_size];
    let mut output = vec![0.0; output_size];
    // Pre-allocate error buffers to avoid per-iteration allocations
    let mut d_output = vec![0.0; output_size];
    let mut d_hidden = vec![0.0; hidden_size];
    let lr = 0.01;

    // 5) Benchmark loop
    let start = Instant::now();
    for _ in 0..iterations {
        // -- Forward pass: input -> hidden
        for j in 0..hidden_size {
            let mut sum = b1[j];
            for i in 0..input_size {
                sum += x[i] * w1[i * hidden_size + j];
            }
            hidden[j] = sum.max(0.0);
        }
        // -- Forward pass: hidden -> output
        for k in 0..output_size {
            let mut sum = b2[k];
            for j in 0..hidden_size {
                sum += hidden[j] * w2[j * output_size + k];
            }
            output[k] = sum;
        }
        // -- Compute output error (d_output)
        for k in 0..output_size {
            d_output[k] = output[k] - y_true[k];
        }
        // -- Initialize d_hidden to zero
        for j in 0..hidden_size {
            d_hidden[j] = 0.0;
        }

        // -- Backprop: update W2, b2, accumulate d_hidden
        for j in 0..hidden_size {
            for k in 0..output_size {
                let idx = j * output_size + k;
                let grad = hidden[j] * d_output[k];
                w2[idx] -= lr * grad;
                d_hidden[j] += w2[idx] * d_output[k];
            }
        }
        for k in 0..output_size {
            b2[k] -= lr * d_output[k];
        }

        // -- Backprop: update W1, b1
        for i in 0..input_size {
            for j in 0..hidden_size {
                let idx = i * hidden_size + j;
                let grad = x[i] * if hidden[j] > 0.0 { d_hidden[j] } else { 0.0 };
                w1[idx] -= lr * grad;
            }
        }
        for j in 0..hidden_size {
            let grad = if hidden[j] > 0.0 { d_hidden[j] } else { 0.0 };
            b1[j] -= lr * grad;
        }
    }
    let elapsed_ms = start.elapsed().as_secs_f64() * 1_000.0;

    // 6) Report results
    println!(
        "input={} hidden={} output={} iters={} time={:.3} ms",
        input_size, hidden_size, output_size, iterations, elapsed_ms
    );
}
