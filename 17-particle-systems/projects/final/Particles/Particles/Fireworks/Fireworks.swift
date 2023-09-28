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

struct Fireworks {
  let particleCount = 10000
  let maxEmitters = 8
  var emitters: [FireworksEmitter] = []
  let life: Float = 256
  var timer: Float = 0

  let clearScreenPSO: MTLComputePipelineState
  let fireworksPSO: MTLComputePipelineState

  init() {
    clearScreenPSO =
      PipelineStates.createComputePSO(function: "clearScreen")
    fireworksPSO =
      PipelineStates.createComputePSO(function: "fireworks")
  }

  mutating func update(size: CGSize) {
    timer += 1
    if timer >= 50 {
      timer = 0
      if emitters.count > maxEmitters {
        emitters.removeFirst()
      }
      let emitter = FireworksEmitter(
        particleCount: particleCount,
        size: size,
        life: life)
      emitters.append(emitter)
    }
  }

  func draw(
    commandBuffer: MTLCommandBuffer,
    view: MTKView
  ) {
    guard let computeEncoder = commandBuffer.makeComputeCommandEncoder(),
      let drawable = view.currentDrawable
      else { return }
    computeEncoder.setComputePipelineState(clearScreenPSO)
    computeEncoder.setTexture(drawable.texture, index: 0)
    var threadsPerGrid = MTLSize(
      width: Int(view.drawableSize.width),
      height: Int(view.drawableSize.height),
      depth: 1)
    let width = clearScreenPSO.threadExecutionWidth
    var threadsPerThreadgroup = MTLSize(
      width: width,
      height: clearScreenPSO.maxTotalThreadsPerThreadgroup / width,
      depth: 1)
    computeEncoder.dispatchThreads(
      threadsPerGrid,
      threadsPerThreadgroup: threadsPerThreadgroup)
    computeEncoder.endEncoding()

    guard let particleEncoder = commandBuffer.makeComputeCommandEncoder()
      else { return }
    particleEncoder.setComputePipelineState(fireworksPSO)
    particleEncoder.setTexture(drawable.texture, index: 0)
    threadsPerGrid = MTLSize(width: particleCount, height: 1, depth: 1)
    for emitter in emitters {
      let particleBuffer = emitter.particleBuffer
      particleEncoder.setBuffer(particleBuffer, offset: 0, index: 0)
      threadsPerThreadgroup = MTLSize(
        width: fireworksPSO.threadExecutionWidth,
        height: 1,
        depth: 1)
      particleEncoder.dispatchThreads(
        threadsPerGrid,
        threadsPerThreadgroup: threadsPerThreadgroup)
    }
    particleEncoder.endEncoding()
  }
}
