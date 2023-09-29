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

struct FlockingPass {
  var particleCount = 100
  let clearScreenPSO = PipelineStates.createComputePSO(function: "clearScreen")
  let boidsPSO = PipelineStates.createComputePSO(function: "boids")
  var emitter: Emitter?

  mutating func resize(view: MTKView, size: CGSize) {
    emitter = Emitter(
      particleCount: particleCount,
      size: size)
  }

  func clearScreen(
    commandEncoder: MTLComputeCommandEncoder,
    texture: MTLTexture
  ) {
    commandEncoder.setComputePipelineState(clearScreenPSO)
    commandEncoder.setTexture(texture, index: 0)
    let width = clearScreenPSO.threadExecutionWidth
    let height = clearScreenPSO.maxTotalThreadsPerThreadgroup / width
    var threadsPerGroup = MTLSize(
      width: width, height: height, depth: 1)
    var threadsPerGrid = MTLSize(
      width: texture.width, height: texture.height, depth: 1)
    #if os(iOS)
    if Renderer.device.supportsFamily(.apple4) {
      commandEncoder.dispatchThreads(
        threadsPerGrid,
        threadsPerThreadgroup: threadsPerGroup)
    } else {
      let width = (Float(texture.width) / Float(width)).rounded(.up)
      let height = (Float(texture.height) / Float(height)).rounded(.up)
      let groupsPerGrid = MTLSize(
        width: Int(width), height: Int(height), depth: 1)
      commandEncoder.dispatchThreadgroups(
        groupsPerGrid,
        threadsPerThreadgroup: threadsPerGroup)
    }
    #elseif os(macOS)
    commandEncoder.dispatchThreads(
      threadsPerGrid,
      threadsPerThreadgroup: threadsPerGroup)
    #endif
  }

  mutating func draw(in view: MTKView, commandBuffer: MTLCommandBuffer) {
    guard let commandEncoder = commandBuffer.makeComputeCommandEncoder(),
      let texture = view.currentDrawable?.texture,
      let emitter = emitter
      else { return }

    clearScreen(
      commandEncoder: commandEncoder,
      texture: texture)

    // render boids
    commandEncoder.setComputePipelineState(boidsPSO)
    let threadsPerGrid = MTLSize(
      width: particleCount, height: 1, depth: 1)
    let threadsPerGroup = MTLSize(width: 1, height: 1, depth: 1)
    commandEncoder.setBuffer(
      emitter.particleBuffer, offset: 0, index: 0)
    commandEncoder.setBytes(
      &particleCount,
      length: MemoryLayout<Int>.stride,
      index: 1)
    #if os(iOS)
    if Renderer.device.supportsFamily(.apple4) {
      commandEncoder.dispatchThreads(
        threadsPerGrid,
        threadsPerThreadgroup: threadsPerGroup)
    } else {
      let threads = min(
        boidsPSO.threadExecutionWidth,
        particleCount)
      let threadsPerThreadgroup = MTLSize(
        width: threads, height: 1, depth: 1)
      let groups = particleCount / threads + 1
      let groupsPerGrid = MTLSize(
        width: groups, height: 1, depth: 1)
      commandEncoder.dispatchThreadgroups(
        groupsPerGrid,
        threadsPerThreadgroup: threadsPerThreadgroup)
    }
    #elseif os(macOS)
    commandEncoder.dispatchThreads(
      threadsPerGrid,
      threadsPerThreadgroup: threadsPerGroup)
    #endif
    commandEncoder.endEncoding()
  }
}
