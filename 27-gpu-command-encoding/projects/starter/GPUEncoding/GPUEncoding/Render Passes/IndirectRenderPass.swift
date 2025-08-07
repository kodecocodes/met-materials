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

// swiftlint:disable implicitly_unwrapped_optional

import MetalKit

struct IndirectRenderPass: RenderPass {
  var label = "Indirect Command Encoding"
  var descriptor: MTLRenderPassDescriptor?
  let depthStencilState: MTLDepthStencilState?
  let pipelineState: MTLRenderPipelineState
  var icb: MTLIndirectCommandBuffer!

  init() {
    pipelineState = PipelineStates.createRenderPSO()
    depthStencilState = Self.buildDepthStencilState()
  }

  mutating func initialize(
    models: [Model],
    uniforms: MTLBuffer
  ) {
    initializeICBCommands(models, uniforms)
  }

  mutating func initializeICBCommands(
    _ models: [Model],
    _ uniforms: MTLBuffer
  ) {
    let icbDescriptor = MTLIndirectCommandBufferDescriptor()
    icbDescriptor.commandTypes = [.drawIndexed]
    icbDescriptor.inheritBuffers = false
    icbDescriptor.maxVertexBufferBindCount = 25
    icbDescriptor.maxFragmentBufferBindCount = 25
    icbDescriptor.inheritPipelineState = true

    guard let icb = Renderer.device.makeIndirectCommandBuffer(
      descriptor: icbDescriptor,
      maxCommandCount: models.count,
      options: []) else { fatalError("Failed to create ICB") }
    icb.label = "ICB for \(models.count) models"
    self.icb = icb

    for (modelIndex, model) in models.enumerated() {
      var modelParams = ModelParams(
        modelMatrix: model.transform.modelMatrix,
        tiling: model.tiling)
      model.modelParamsBuffer.contents().copyMemory(
        from: &modelParams,
        byteCount: MemoryLayout<ModelParams>.stride)
      let mesh = model.meshes[0]
      let submesh = mesh.submeshes[0]
      let icbCommand = icb.indirectRenderCommandAt(modelIndex)
      icbCommand.setVertexBuffer(
        uniforms, offset: 0, at: UniformsBuffer.index)
      icbCommand.setVertexBuffer(
        model.modelParamsBuffer, offset: 0, at: ModelParamsBuffer.index)
      icbCommand.setFragmentBuffer(
        model.modelParamsBuffer, offset: 0, at: ModelParamsBuffer.index)
      icbCommand.setVertexBuffer(
        mesh.vertexBuffers[VertexBuffer.index],
        offset: 0,
        at: VertexBuffer.index)
      icbCommand.setVertexBuffer(
        mesh.vertexBuffers[UVBuffer.index],
        offset: 0,
        at: UVBuffer.index)
      icbCommand.setFragmentBuffer(
        submesh.materialBuffer, offset: 0, at: MaterialBuffer.index)
      icbCommand.drawIndexedPrimitives(
        .triangle,
        indexCount: submesh.indexCount,
        indexType: submesh.indexType,
        indexBuffer: submesh.indexBuffer,
        indexBufferOffset: submesh.indexBufferOffset,
        instanceCount: 1,
        baseVertex: 0,
        baseInstance: 0)
    }
  }

  mutating func resize(view: MTKView, size: CGSize) {
  }

  func useResources(
    encoder: MTLRenderCommandEncoder, models: [Model]
  ) {
    encoder.pushDebugGroup("Using resources")
    for model in models {
      let mesh = model.meshes[0]
      let submesh = mesh.submeshes[0]
      [
        model.modelParamsBuffer,
        mesh.vertexBuffers[VertexBuffer.index],
        mesh.vertexBuffers[UVBuffer.index],
        submesh.indexBuffer
      ].forEach { buffer in
        encoder.useResource(buffer, usage: .read, stages: .vertex)
      }
      [
        model.modelParamsBuffer,
        submesh.materialBuffer
      ].forEach { buffer in
        encoder.useResource(buffer, usage: .read, stages: .fragment)
      }
    }
    encoder.popDebugGroup()
  }

  func draw(
    commandBuffer: MTLCommandBuffer,
    scene: GameScene,
    uniforms: MTLBuffer
  ) {
    guard let descriptor = descriptor,
      let renderEncoder =
      commandBuffer.makeRenderCommandEncoder(
        descriptor: descriptor) else {
      return
    }
    useResources(encoder: renderEncoder, models: scene.models)
    renderEncoder.label = label
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.setVertexBuffer(
      uniforms, offset: 0, index: UniformsBuffer.index)

    renderEncoder.executeCommandsInBuffer(
      icb, range: 0..<scene.models.count)

    renderEncoder.endEncoding()
  }
}

// swiftlint:enable implicitly_unwrapped_optional
