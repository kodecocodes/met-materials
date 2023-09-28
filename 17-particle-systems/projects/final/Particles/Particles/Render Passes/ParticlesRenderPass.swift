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

struct ParticlesRenderPass: RenderPass {
  var label: String = "Particle Effects"
  var descriptor: MTLRenderPassDescriptor?

  var size: CGSize = .zero

  let computePSO: MTLComputePipelineState
  let renderPSO: MTLRenderPipelineState
  let blendingPSO: MTLRenderPipelineState

  init(view: MTKView) {
    computePSO = PipelineStates.createComputePSO(
      function: "computeParticles")
    renderPSO = PipelineStates.createParticleRenderPSO(
      pixelFormat: view.colorPixelFormat)
    blendingPSO = PipelineStates.createParticleRenderPSO(
      pixelFormat: view.colorPixelFormat,
      enableBlending: true)
  }

  mutating func resize(view: MTKView, size: CGSize) {
    self.size = size
  }

  func update(
    commandBuffer: MTLCommandBuffer,
    scene: GameScene
  ) {
    guard let computeEncoder =
      commandBuffer.makeComputeCommandEncoder() else { return }
    computeEncoder.label = label
    computeEncoder.setComputePipelineState(computePSO)
    let threadsPerGroup = MTLSize(
      width: computePSO.threadExecutionWidth, height: 1, depth: 1)
    for emitter in scene.particleEffects {
      emitter.emit()
      if emitter.currentParticles <= 0 { continue }
      let threadsPerGrid = MTLSize(
        width: emitter.particleCount, height: 1, depth: 1)
      computeEncoder.setBuffer(
        emitter.particleBuffer,
        offset: 0,
        index: 0)
      computeEncoder.dispatchThreads(
        threadsPerGrid,
        threadsPerThreadgroup: threadsPerGroup)
    }
    computeEncoder.endEncoding()
  }

  func render(
    commandBuffer: MTLCommandBuffer,
    scene: GameScene
  ) {
    guard let descriptor = descriptor,
      let renderEncoder =
        commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
      else { return }
    renderEncoder.label = label
    var size: float2 = [Float(size.width), Float(size.height)]
    renderEncoder.setVertexBytes(
      &size,
      length: MemoryLayout<float2>.stride,
      index: 0)

    for emitter in scene.particleEffects {
      if emitter.currentParticles <= 0 { continue }
      renderEncoder.setRenderPipelineState(
        emitter.blending ? blendingPSO : renderPSO)
      renderEncoder.setVertexBuffer(
        emitter.particleBuffer,
        offset: 0,
        index: 1)
      renderEncoder.setVertexBytes(
        &emitter.position,
        length: MemoryLayout<float2>.stride,
        index: 2)
      renderEncoder.setFragmentTexture(
        emitter.particleTexture,
        index: 0)
      renderEncoder.drawPrimitives(
        type: .point,
        vertexStart: 0,
        vertexCount: 1,
        instanceCount: emitter.currentParticles)
    }
    renderEncoder.endEncoding()
  }

  func draw(
    commandBuffer: MTLCommandBuffer,
    scene: GameScene,
    uniforms: Uniforms,
    params: Params
  ) {
    update(commandBuffer: commandBuffer, scene: scene)
    render(commandBuffer: commandBuffer, scene: scene)
  }
}
