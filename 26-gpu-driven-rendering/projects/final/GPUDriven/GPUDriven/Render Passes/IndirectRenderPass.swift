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

struct IndirectRenderPass: RenderPass {
  var label = "Indirect Command Encoding"
  var descriptor: MTLRenderPassDescriptor?
  let depthStencilState: MTLDepthStencilState?
  let pipelineState: MTLRenderPipelineState
  var uniformsBuffer: MTLBuffer!
  var modelParamsBuffer: MTLBuffer!
  var icb: MTLIndirectCommandBuffer!
  let icbPipelineState: MTLComputePipelineState
  let icbComputeFunction: MTLFunction
  var icbBuffer: MTLBuffer!
  var modelsBuffer: MTLBuffer!
  var drawArgumentsBuffer: MTLBuffer!

  init() {
    pipelineState = PipelineStates.createIndirectPSO()
    depthStencilState = Self.buildDepthStencilState()
    icbComputeFunction =
      Renderer.library.makeFunction(name: "encodeCommands")!
    icbPipelineState = PipelineStates.createComputePSO(
      function: "encodeCommands")
  }

  mutating func initialize(models: [Model]) {
    initializeUniforms(models)
    initializeICBCommands(models)
    initializeModels(models)
    initializeDrawArguments(models: models)
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
    self.icb = icb
    let icbEncoder = icbComputeFunction.makeArgumentEncoder(
      bufferIndex: ICBBuffer.index)
    icbBuffer = Renderer.device.makeBuffer(
      length: icbEncoder.encodedLength,
      options: [])
    icbEncoder.setArgumentBuffer(icbBuffer, offset: 0)
    icbEncoder.setIndirectCommandBuffer(icb, index: 0)
  }

  mutating func initializeModels(_ models: [Model]) {
    let encoder = icbComputeFunction.makeArgumentEncoder(
      bufferIndex: ModelsBuffer.index)
    modelsBuffer = Renderer.device.makeBuffer(
      length: encoder.encodedLength * models.count, options: [])
    for (index, model) in models.enumerated() {
      let mesh = model.meshes[0]
      let submesh = mesh.submeshes[0]
      encoder.setArgumentBuffer(
        modelsBuffer, startOffset: 0, arrayElement: index)
      encoder.setBuffer(
        mesh.vertexBuffers[VertexBuffer.index], offset: 0, index: 0)
      encoder.setBuffer(
        mesh.vertexBuffers[UVBuffer.index],
        offset: 0,
        index: 1)
      encoder.setBuffer(
        submesh.indexBuffer,
        offset: submesh.indexBufferOffset,
        index: 2)
      encoder.setBuffer(submesh.argumentBuffer!, offset: 0, index: 3)
    }
  }

  mutating func initializeDrawArguments(models: [Model]) {
    let drawLength = models.count *
      MemoryLayout<MTLDrawIndexedPrimitivesIndirectArguments>.stride
    drawArgumentsBuffer = Renderer.device.makeBuffer(
      length: drawLength, options: [])
    drawArgumentsBuffer.label = "Draw Arguments"
    var drawPointer =
      drawArgumentsBuffer.contents().bindMemory(
        to: MTLDrawIndexedPrimitivesIndirectArguments.self,
        capacity: models.count)
    for (modelIndex, model) in models.enumerated() {
      let mesh = model.meshes[0]
      let submesh = mesh.submeshes[0]
      var drawArgument = MTLDrawIndexedPrimitivesIndirectArguments()
      drawArgument.indexCount = UInt32(submesh.indexCount)
      drawArgument.indexStart = UInt32(submesh.indexBufferOffset)
      drawArgument.instanceCount = 1
      drawArgument.baseVertex = 0
      drawArgument.baseInstance = UInt32(modelIndex)
      drawPointer.pointee = drawArgument
      drawPointer = drawPointer.advanced(by: 1)
    }
  }

  mutating func initializeUniforms(_ models: [Model]) {
    let bufferLength = MemoryLayout<Uniforms>.stride
    uniformsBuffer =
      Renderer.device.makeBuffer(length: bufferLength, options: [])
    uniformsBuffer.label = "Uniforms"

    var modelParams: [ModelParams] = models.map { model in
      var modelParams = ModelParams()
      modelParams.modelMatrix = model.transform.modelMatrix
      modelParams.normalMatrix = modelParams.modelMatrix.upperLeft
      modelParams.tiling = model.tiling
      return modelParams
    }
    modelParamsBuffer = Renderer.device.makeBuffer(
      bytes: &modelParams,
      length: MemoryLayout<ModelParams>.stride * models.count,
      options: [])
    modelParamsBuffer.label = "Model Transforms Array"
  }

  mutating func resize(view: MTKView, size: CGSize) {
  }

  func updateUniforms(scene: GameScene, uniforms: Uniforms) {
    var uniforms = uniforms
    uniformsBuffer.contents().copyMemory(
      from: &uniforms,
      byteCount: MemoryLayout<Uniforms>.stride)
  }

  func useResources(
    encoder: MTLComputeCommandEncoder, models: [Model]
  ) {
    encoder.pushDebugGroup("Using resources")
    encoder.useResource(icb, usage: .write)
    encoder.useResource(
      uniformsBuffer,
      usage: .read)
    encoder.useResource(
      modelParamsBuffer,
      usage: .read)
    if let heap = TextureController.heap {
      encoder.useHeap(heap)
    }
    for model in models {
      let mesh = model.meshes[0]
      let submesh = mesh.submeshes[0]
      encoder.useResource(
        mesh.vertexBuffers[VertexBuffer.index],
        usage: .read)
      encoder.useResource(
        mesh.vertexBuffers[UVBuffer.index],
        usage: .read)
      encoder.useResource(
        submesh.indexBuffer, usage: .read)
      encoder.useResource(
        submesh.argumentBuffer!, usage: .read)
    }
    encoder.popDebugGroup()
  }

  func encodeDraw(encoder: MTLComputeCommandEncoder) {
    encoder.setComputePipelineState(icbPipelineState)
    encoder.setBuffer(
      icbBuffer, offset: 0, index: ICBBuffer.index)
    encoder.setBuffer(
      uniformsBuffer, offset: 0, index: UniformsBuffer.index)
    encoder.setBuffer(
      modelsBuffer, offset: 0, index: ModelsBuffer.index)
    encoder.setBuffer(
      modelParamsBuffer, offset: 0, index: ModelParamsBuffer.index)
    encoder.setBuffer(
      drawArgumentsBuffer, offset: 0, index: DrawArgumentsBuffer.index)
  }

  func dispatchThreads(
    encoder: MTLComputeCommandEncoder,
    drawCount: Int
  ) {
    let threadExecutionWidth = icbPipelineState.threadExecutionWidth
    let threads = MTLSize(width: drawCount, height: 1, depth: 1)
    let threadsPerThreadgroup = MTLSize(
      width: threadExecutionWidth, height: 1, depth: 1)
    encoder.dispatchThreads(
      threads,
      threadsPerThreadgroup: threadsPerThreadgroup)
  }

  func draw(
    commandBuffer: MTLCommandBuffer,
    scene: GameScene,
    uniforms: Uniforms,
    params: Params
  ) {
    updateUniforms(scene: scene, uniforms: uniforms)
    guard
      let computeEncoder = commandBuffer.makeComputeCommandEncoder()
      else { return }
    encodeDraw(encoder: computeEncoder)
    useResources(encoder: computeEncoder, models: scene.models)
    dispatchThreads(
      encoder: computeEncoder, drawCount: scene.models.count)
    computeEncoder.endEncoding()
    guard let descriptor = descriptor,
      let renderEncoder =
      commandBuffer.makeRenderCommandEncoder(
        descriptor: descriptor) else {
      return
    }
    renderEncoder.label = label
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.executeCommandsInBuffer(
      icb, range: 0..<scene.models.count)
    renderEncoder.endEncoding()
  }
}
