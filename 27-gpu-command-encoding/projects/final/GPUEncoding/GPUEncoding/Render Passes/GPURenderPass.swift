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
// swiftlint:disable force_unwrapping

import MetalKit

struct GPURenderPass: RenderPass {
  var label = "GPU Command Encoding"
  var descriptor: MTLRenderPassDescriptor?
  let depthStencilState: MTLDepthStencilState?
  let pipelineState: MTLRenderPipelineState
  var icb: MTLIndirectCommandBuffer!
  let icbPipelineState: MTLComputePipelineState
  let icbComputeFunction: MTLFunction
  var icbContainer: MTLBuffer!

  var sceneBuffer: MTLBuffer!
  var modelParamsBufferArray: [MTLBuffer] = []

  init() {
    pipelineState = PipelineStates.createRenderPSO()
    depthStencilState = Self.buildDepthStencilState()
    icbComputeFunction =
      Renderer.library.makeFunction(name: "encodeICB")!
    icbPipelineState = PipelineStates.createComputePSO(
      function: "encodeICB")
  }

  mutating func initialize(models: [Model]) {
    initializeICBCommands(models)

    let sceneBufferSize = MemoryLayout<SceneData>.stride * models.count
    sceneBuffer = Renderer.device.makeBuffer(length: sceneBufferSize)!
    sceneBuffer.label = "Scene Buffer"
    var scenePtr = sceneBuffer.contents()
      .assumingMemoryBound(to: SceneData.self)
    for model in models {
      let mesh = model.meshes[0]
      let submesh = mesh.submeshes[0]

      scenePtr.pointee.positions = mesh.vertexBuffers[0].gpuAddress
      scenePtr.pointee.uvs = mesh.vertexBuffers[1].gpuAddress
      scenePtr.pointee.indices = submesh.indexBuffer.gpuAddress
      scenePtr.pointee.indexType = submesh.indexType == .uint16 ? 0 : 1
      scenePtr.pointee.indexCount = UInt32(submesh.indexCount)
      scenePtr.pointee.materials = model.meshes[0].submeshes[0]
        .materialBuffer.gpuAddress

      var modelParams = ModelParams(
        modelMatrix: model.transform.modelMatrix,
        tiling: model.tiling)
      let modelParamsBufferSize = MemoryLayout<ModelParams>.stride
      let modelParamsBuffer = Renderer.device.makeBuffer(
        bytes: &modelParams, length: modelParamsBufferSize)!
      modelParamsBuffer.label = "Model Params"
      scenePtr.pointee.modelParams = modelParamsBuffer.gpuAddress
      modelParamsBufferArray.append(modelParamsBuffer)

      scenePtr = scenePtr.advanced(by: 1)
    }
  }

  mutating func initializeICBCommands(_ models: [Model]) {
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

    let icbEncoder = icbComputeFunction.makeArgumentEncoder(
      bufferIndex: ICBBuffer.index)
    icbContainer = Renderer.device.makeBuffer(
      length: icbEncoder.encodedLength,
      options: [])
    icbEncoder.setArgumentBuffer(icbContainer, offset: 0)
    icbEncoder.setIndirectCommandBuffer(icb, index: 0)
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

    encoder.useResource(sceneBuffer, usage: .read, stages: [.vertex, .fragment])
    modelParamsBufferArray.forEach {
      encoder.useResource($0, usage: .read, stages: [.vertex, .fragment])
    }
    encoder.popDebugGroup()
  }

  func encodeICB(
    commandBuffer: MTLCommandBuffer,
    models: [Model],
    uniforms: MTLBuffer
  ) {
    guard let computeEncoder =
      commandBuffer.makeComputeCommandEncoder() else { return }
    computeEncoder.label = "GPU Encoding"

    computeEncoder.setComputePipelineState(icbPipelineState)
    computeEncoder.setBuffer(sceneBuffer, offset: 0, index: 0)
    computeEncoder.setBuffer(
      uniforms, offset: 0, index: UniformsBuffer.index)
    computeEncoder.setBuffer(
      icbContainer, offset: 0, index: ICBBuffer.index)

    // Dispatch threads
    let threadExecutionWidth = icbPipelineState.threadExecutionWidth
    let drawCount = models.count // should be number of draw calls
    let threads = MTLSize(width: drawCount, height: 1, depth: 1)
    let threadsPerThreadgroup = MTLSize(
      width: threadExecutionWidth, height: 1, depth: 1)
    computeEncoder.dispatchThreads(
      threads, threadsPerThreadgroup: threadsPerThreadgroup)
    computeEncoder.endEncoding()
  }

  func draw(
    commandBuffer: MTLCommandBuffer,
    scene: GameScene,
    uniforms: MTLBuffer
  ) {
    encodeICB(
      commandBuffer: commandBuffer,
      models: scene.models,
      uniforms: uniforms)
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
// swiftlint:enable force_unwrapping
