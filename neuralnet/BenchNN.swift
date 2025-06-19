import Foundation

guard CommandLine.arguments.count == 5,
      let inputSize  = Int(CommandLine.arguments[1]), inputSize  > 0,
      let hiddenSize = Int(CommandLine.arguments[2]), hiddenSize > 0,
      let outputSize = Int(CommandLine.arguments[3]), outputSize > 0,
      let iterations = Int(CommandLine.arguments[4]), iterations > 0
else {
    fputs("Usage: bench-swift-nn <inputSize> <hiddenSize> <outputSize> <iterations>\n", stderr)
    exit(1)
}

func randArray(_ count: Int) -> [Double] {
    (0..<count).map { _ in Double.random(in: -1.0...1.0) }
}

// 1) Allocate
var W1 = randArray(inputSize * hiddenSize)
var b1 = [Double](repeating: 0, count: hiddenSize)
var W2 = randArray(hiddenSize * outputSize)
var b2 = [Double](repeating: 0, count: outputSize)
let x     = randArray(inputSize)
let yTrue = randArray(outputSize)

// 2) Working buffers
var hidden = [Double](repeating: 0, count: hiddenSize)
var output = [Double](repeating: 0, count: outputSize)
let lr = 0.01

// 3) Benchmark loop
let start = DispatchTime.now()
for _ in 0..<iterations {
  // forward → hidden
  for j in 0..<hiddenSize {
    var sum = b1[j]
    for i in 0..<inputSize {
      sum += x[i] * W1[i*hiddenSize + j]
    }
    hidden[j] = sum > 0 ? sum : 0
  }
  // forward → output
  for k in 0..<outputSize {
    var sum = b2[k]
    for j in 0..<hiddenSize {
      sum += hidden[j] * W2[j*outputSize + k]
    }
    output[k] = sum
  }
  // compute output error
  var dOutput = [Double](repeating: 0, count: outputSize)
  for k in 0..<outputSize {
    dOutput[k] = output[k] - yTrue[k]
  }
  // backprop → W2, b2, and dHidden
  var dHidden = [Double](repeating: 0, count: hiddenSize)
  for j in 0..<hiddenSize {
    for k in 0..<outputSize {
      let idx = j*outputSize + k
      let grad = hidden[j] * dOutput[k]
      W2[idx] -= lr * grad
      dHidden[j] += W2[idx] * dOutput[k]
    }
  }
  for k in 0..<outputSize {
    b2[k] -= lr * dOutput[k]
  }
  // backprop → W1, b1
  for i in 0..<inputSize {
    for j in 0..<hiddenSize {
      let idx = i*hiddenSize + j
      let grad = x[i] * (hidden[j] > 0 ? dHidden[j] : 0.0)
      W1[idx] -= lr * grad
    }
  }
  for j in 0..<hiddenSize {
    let grad = hidden[j] > 0 ? dHidden[j] : 0.0
    b1[j] -= lr * grad
  }
}
let end = DispatchTime.now()

// 4) Report
let ms = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
let timeStr = String(format: "%.3f", ms)
print("input=\(inputSize) hidden=\(hiddenSize) output=\(outputSize) iters=\(iterations) time=\(timeStr) ms")
