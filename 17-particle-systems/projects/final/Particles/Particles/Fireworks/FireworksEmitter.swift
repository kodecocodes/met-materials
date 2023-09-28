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

struct FireworksEmitter {
  let particleBuffer: MTLBuffer

  init(
    particleCount: Int,
    size: CGSize,
    life: Float
  ) {
    let bufferSize =
      MemoryLayout<Particle>.stride * particleCount
    particleBuffer =
      Renderer.device.makeBuffer(length: bufferSize)!

    let width = Float(size.width)
    let height = Float(size.height)
    let position = float2(
      Float.random(in: 0...width),
      Float.random(in: 0...height))
    let color = float4(
      Float.random(in: 0...life) / life,
      Float.random(in: 0...life) / life,
      Float.random(in: 0...life) / life,
      1)

    var pointer =
      particleBuffer.contents().bindMemory(
        to: Particle.self,
        capacity: particleCount)
    for _ in 0..<particleCount {
      let direction =
        2 * Float.pi * Float.random(in: 0...width) / width
      let speed = 3 * Float.random(in: 0...width) / width
      pointer.pointee.position = position
      pointer.pointee.direction = direction
      pointer.pointee.speed = speed
      pointer.pointee.color = color
      pointer.pointee.life = life
      pointer = pointer.advanced(by: 1)
    }
  }
}
