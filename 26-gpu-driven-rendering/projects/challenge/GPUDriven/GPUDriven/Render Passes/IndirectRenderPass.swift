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
// swiftlint:disable implicitly_unwrapped_optional

struct IndirectRenderPass: RenderPass {
  let label = "Indirect Render Pass"
  var descriptor: MTLRenderPassDescriptor?
  var pipelineState: MTLRenderPipelineState
  let depthStencilState: MTLDepthStencilState?

  var uniformsBuffer: MTLBuffer
  var paramsBuffer: MTLBuffer
  var modelParamsBuffer: MTLBuffer!
  let icbPipelineState: MTLComputePipelineState
  let icbComputeFunction: MTLFunction // needed?
  var icb: MTLIndirectCommandBuffer!
  var icbBuffer: MTLBuffer!
  var modelsBuffer: MTLBuffer!
  var drawArgumentsBuffer: MTLBuffer!
  var submeshesBuffer: MTLBuffer!

  var drawCount = 0

  init() {
    depthStencilState = Self.buildDepthStencilState()
    pipelineState = PipelineStates.createSimplePSO()

    var bufferLength = MemoryLayout<Uniforms>.stride
    uniformsBuffer =
      Renderer.device.makeBuffer(length: bufferLength, options: [])!
    uniformsBuffer.label = "Uniforms"
    bufferLength = MemoryLayout<Params>.stride
    paramsBuffer =
      Renderer.device.makeBuffer(length: bufferLength, options: [])!
    paramsBuffer.label = "Fragment Uniforms"

    icbComputeFunction =
      Renderer.library.makeFunction(name: "encodeCommands")!
    icbPipelineState = PipelineStates.createComputePSO(function: "encodeCommands")
  }

  mutating func initialize(models: [Model]) {
    drawCount = models.reduce(0) {
      $0 + $1.meshes[0].submeshes.count
    }
    initializeUniforms(models)
    initializeICBCommands(models)
    initializeSubmeshes(models)
    initializeDrawArguments(models)
  }

  mutating func initializeICBCommands(_ models: [Model]) {
    let icbDescriptor = MTLIndirectCommandBufferDescriptor()
    icbDescriptor.commandTypes = [.drawIndexed]
    icbDescriptor.inheritBuffers = false
    icbDescriptor.maxVertexBufferBindCount = 25
    icbDescriptor.maxFragmentBufferBindCount = 25
    icbDescriptor.inheritPipelineState = false
    let icb = Renderer.device.makeIndirectCommandBuffer(
      descriptor: icbDescriptor,
      maxCommandCount: drawCount,
      options: [])
    self.icb = icb
    let icbEncoder = icbComputeFunction.makeArgumentEncoder(
      bufferIndex: ICBBuffer.index)
    icbBuffer = Renderer.device.makeBuffer(
      length: icbEncoder.encodedLength,
      options: [])!
    icbBuffer.label = "ICB Buffer"
    icbEncoder.setArgumentBuffer(icbBuffer, offset: 0)
    icbEncoder.setIndirectCommandBuffer(icb, index: 0)
  }

  mutating func initializeUniforms(_ models: [Model]) {
    uniformsBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<Uniforms>.stride, options: [])!
    uniformsBuffer.label = "Uniforms"
    paramsBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<Params>.stride, options: [])!
    paramsBuffer.label = "Fragment Uniforms"

    modelParamsBuffer = Renderer.device.makeBuffer(
      length: models.count * MemoryLayout<ModelParams>.stride,
      options: [])!
    modelParamsBuffer.label = "Model Parameters"

    let encoder = icbComputeFunction.makeArgumentEncoder(
      bufferIndex: ModelsArrayBuffer.index)
    modelsBuffer = Renderer.device.makeBuffer(
      length: encoder.encodedLength * models.count, options: [])!
    for (index, model) in models.enumerated() {
      let mesh = model.meshes[0]
      encoder.setArgumentBuffer(modelsBuffer, startOffset: 0, arrayElement: index)
      mesh.vertexBuffers[Position.index].label = "Positions \(index)"
      encoder.setBuffer(
        mesh.vertexBuffers[Position.index],
        offset: 0,
        index: 0)
      encoder.setBuffer(mesh.vertexBuffers[UV.index], offset: 0, index: 1)
    }
  }

  mutating func initializeSubmeshes(_ models: [Model]) {
    modelsBuffer.label = "Models Array Buffer"
    let encoder = icbComputeFunction.makeArgumentEncoder(
      bufferIndex: SubmeshesArrayBuffer.index)
    submeshesBuffer = Renderer.device.makeBuffer(
      length: encoder.encodedLength * drawCount, options: [])!
    var submeshIndex = 0
    for (modelIndex, model) in models.enumerated() {
      let mesh = model.meshes[0]
      for submesh in mesh.submeshes {
        encoder.setArgumentBuffer(submeshesBuffer, startOffset: 0, arrayElement: submeshIndex)
        encoder.setBuffer(
          submesh.indexBuffer, offset: 0, index: 0)
        encoder.setBuffer(
          submesh.materialsBuffer, offset: 0, index: 1)
        submeshIndex += 1
        let pointer = submesh.modelIndexBuffer.contents()
          .bindMemory(to: UInt32.self, capacity: 1)
        pointer.pointee = UInt32(modelIndex)
        encoder.setBuffer(submesh.modelIndexBuffer, offset: 0, index: 2)
        encoder.setRenderPipelineState(pipelineState, index: 3)
      }
    }
  }

  mutating func initializeDrawArguments(_ models: [Model]) {
    let drawLength = drawCount *
      MemoryLayout<MTLDrawIndexedPrimitivesIndirectArguments>.stride
    drawArgumentsBuffer = Renderer.device.makeBuffer(
      length: drawLength,
      options: [])!
    drawArgumentsBuffer.label = "Draw Arguments"
    var drawPointer =
      drawArgumentsBuffer.contents().bindMemory(
        to: MTLDrawIndexedPrimitivesIndirectArguments.self,
        capacity: drawCount)
    var drawCount = 0
    for model in models {
      for mesh in  model.meshes {
        for submesh in mesh.submeshes {
          var drawArgument = MTLDrawIndexedPrimitivesIndirectArguments()
          drawArgument.indexCount = UInt32(submesh.indexCount)
          drawArgument.instanceCount = 1
          drawArgument.indexStart =
            UInt32(submesh.indexBufferOffset)
          drawArgument.baseVertex = 0
          drawArgument.baseInstance = 0
          drawPointer.pointee = drawArgument
          drawPointer = drawPointer.advanced(by: 1)
          drawCount += 1
        }
      }
    }
  }

  mutating func resize(view: MTKView, size: CGSize) {
  }

  func updateUniforms(scene: GameScene, uniforms: Uniforms, params: Params) {
    var uniforms = uniforms
    var bufferLength = MemoryLayout<Uniforms>.stride
    uniformsBuffer.contents().copyMemory(
      from: &uniforms,
      byteCount: bufferLength)
    var params = params
    bufferLength = MemoryLayout<Params>.stride
    paramsBuffer.contents().copyMemory(
      from: &params,
      byteCount: bufferLength)
    var pointer = modelParamsBuffer.contents().bindMemory(
      to: ModelParams.self,
      capacity: scene.staticModels.count)
    for model in scene.staticModels {
      pointer.pointee.modelMatrix = model.transform.modelMatrix
      pointer.pointee.tiling = model.tiling
      pointer = pointer.advanced(by: 1)
    }
  }

  func draw(
    commandBuffer: MTLCommandBuffer,
    scene: GameScene,
    uniforms: Uniforms,
    params: Params
  ) {
    var params = params
    params.alphaTesting = true
    updateUniforms(scene: scene, uniforms: uniforms, params: params)
    guard
      let computeEncoder = commandBuffer.makeComputeCommandEncoder()
      else { return }
    computeEncoder.setComputePipelineState(icbPipelineState)
    computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: UniformsBuffer.index)
    computeEncoder.setBuffer(paramsBuffer, offset: 0, index: ParamsBuffer.index)
    computeEncoder.setBuffer(drawArgumentsBuffer, offset: 0, index: DrawArgumentsBuffer.index)
    computeEncoder.setBuffer(modelParamsBuffer, offset: 0, index: ModelParamsBuffer.index)
    computeEncoder.setBuffer(modelsBuffer, offset: 0, index: ModelsArrayBuffer.index)
    computeEncoder.setBuffer(submeshesBuffer, offset: 0, index: SubmeshesArrayBuffer.index)
    computeEncoder.setBuffer(icbBuffer, offset: 0, index: ICBBuffer.index)
    computeEncoder.useResource(icb, usage: .write)
    computeEncoder.useResource(modelsBuffer, usage: .read)

    if let heap = TextureController.heap {
      computeEncoder.useHeap(heap)
    }

    computeEncoder.useResource(modelParamsBuffer, usage: .read)
    for model in scene.staticModels {
      for mesh in model.meshes {
        computeEncoder.useResource(mesh.vertexBuffers[Position.index], usage: .read)
        computeEncoder.useResource(mesh.vertexBuffers[UV.index], usage: .read)
        for submesh in mesh.submeshes {
          computeEncoder.useResource(submesh.indexBuffer, usage: .read)
          computeEncoder.useResource(submesh.materialsBuffer, usage: .read)
        }
      }
    }

    let threadExecutionWidth = icbPipelineState.threadExecutionWidth
    let threads = MTLSize(width: drawCount, height: 1, depth: 1)
    let threadsPerThreadgroup = MTLSize(
      width: threadExecutionWidth, height: 1, depth: 1)
    computeEncoder.dispatchThreads(
      threads,
      threadsPerThreadgroup: threadsPerThreadgroup)
    computeEncoder.endEncoding()
    let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
    blitEncoder.optimizeIndirectCommandBuffer(icb, range: 0..<drawCount)
    blitEncoder.endEncoding()

    descriptor?.depthAttachment.storeAction = .store
    descriptor?.colorAttachments[0].storeAction = .store
    guard let renderEncoder =
      commandBuffer.makeRenderCommandEncoder(descriptor: descriptor!) else {
        return
    }
    renderEncoder.label = label
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.executeCommandsInBuffer(icb, range: 0..<drawCount)
    renderEncoder.endEncoding()
  }
}
// swiftlint:enable force_unwrapping
// swiftlint:enable implicitly_unwrapped_optional
