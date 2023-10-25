///// Copyright (c) 2023 Kodeco Inc.
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

import MetalKit
// swiftlint:disable force_unwrapping

struct Emitter {
  var particleBuffer: MTLBuffer!

  init(
    options: Options,
    size: CGSize,
    device: MTLDevice
  ) {
    let bufferSize = MemoryLayout<Particle>.stride * options.particleCount
    particleBuffer = device.makeBuffer(length: bufferSize)
    var pointer = particleBuffer.contents().bindMemory(
      to: Particle.self,
      capacity: options.particleCount)
    pointer.pointee.velocity = float2(options.predatorSpeed, options.predatorSpeed)
    pointer.pointee.position = float2(
      random(Int(size.width)),
      random(Int(size.height)))
    pointer = pointer.advanced(by: 1)
    for _ in 1..<options.particleCount {
      let xPosition = random(Int(size.width))
      let yPosition = random(Int(size.height))
      let position = float2(xPosition, yPosition)
      pointer.pointee.position = position
      let range: ClosedRange<Float> = -options.maxSpeed...options.maxSpeed
      let velocity = float2(Float.random(in: range), Float.random(in: range))
      pointer.pointee.velocity = velocity
      pointer = pointer.advanced(by: 1)
    }
  }

  func random(_ max: Int) -> Float {
    guard max > 0 else { return 0 }
    return Float.random(in: 0..<Float(max))
  }
}
// swiftlint:enable force_unwrapping
