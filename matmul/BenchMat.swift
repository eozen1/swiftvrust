import Foundation

// 1) Parse N
guard CommandLine.arguments.count == 2,
      let N = Int(CommandLine.arguments[1]),
      N > 0 else {
    fputs("Usage: bench-swift-mat <positive-integer>\n", stderr)
    exit(1)
}

// 2) Allocate and fill A, B
var A = [Double](repeating: 0, count: N * N)
var B = [Double](repeating: 0, count: N * N)
for i in 0..<N*N {
    let r = Double.random(in: 0..<1)
    A[i] = r
    B[i] = r
}

// 3) Prepare C
var C = [Double](repeating: 0, count: N * N)

// 4) Time the multiply
let start = DispatchTime.now()
for i in 0..<N {
  let rowBase = i * N
  for j in 0..<N {
    var sum: Double = 0
    for k in 0..<N {
      sum += A[rowBase + k] * B[k * N + j]
    }
    C[rowBase + j] = sum
  }
}
let end = DispatchTime.now()

// 5) Report
let ms = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
let timeStr = String(format: "%.3f", ms)
print("N=\(N)  time=\(timeStr) ms")
