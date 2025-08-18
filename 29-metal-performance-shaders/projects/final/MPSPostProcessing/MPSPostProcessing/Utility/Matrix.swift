///// Copyright (c) 2025 Kodeco Inc.
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

// swiftlint:disable fatal_error_message
// swiftlint:disable identifier_name

import Playgrounds
import MetalPerformanceShaders

#Playground {
  guard let device = MTLCreateSystemDefaultDevice(),
    let commandQueue = device.makeCommandQueue()
  else { fatalError() }

  let size = 4
  let count = size * size

  func createMPSMatrix(withRepeatingValue: Float) -> MPSMatrix {
    let rowBytes = MPSMatrixDescriptor.rowBytes(
      forColumns: size,
      dataType: .float32)
    let array = [Float](
      repeating: withRepeatingValue,
      count: count)
    guard let buffer = device.makeBuffer(
      bytes: array,
      length: size * rowBytes,
      options: [])
    else { fatalError() }
    let matrixDescriptor = MPSMatrixDescriptor(
      rows: size,
      columns: size,
      rowBytes: rowBytes,
      dataType: .float32)

    return MPSMatrix(buffer: buffer, descriptor: matrixDescriptor)
  }

  let A = createMPSMatrix(withRepeatingValue: 3)
  let B = createMPSMatrix(withRepeatingValue: 2)
  let C = createMPSMatrix(withRepeatingValue: 1)

  let multiplicationKernel = MPSMatrixMultiplication(
    device: device,
    transposeLeft: false,
    transposeRight: false,
    resultRows: size,
    resultColumns: size,
    interiorColumns: size,
    alpha: 1.0,
    beta: 0.0)
  guard let commandBuffer = commandQueue.makeCommandBuffer()
    else { fatalError() }

  multiplicationKernel.encode(
    commandBuffer: commandBuffer,
    leftMatrix: A,
    rightMatrix: B,
    resultMatrix: C)

  commandBuffer.commit()
  await commandBuffer.completed()
  let contents = C.data.contents()
  let pointer = contents.bindMemory(
    to: Float.self,
    capacity: count)
  (0..<count).forEach {
    _ = pointer.advanced(by: $0).pointee
  }
}

// swiftlint:enable fatal_error_message
// swiftlint:enable identifier_name
