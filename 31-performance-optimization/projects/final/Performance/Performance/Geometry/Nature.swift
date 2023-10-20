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
// swiftlint:disable force_cast

class Nature: Transformable {
  let modelTransformBuffers: [MTLBuffer]
  let instanceCount: Int
  let instanceBuffer: MTLBuffer
  let pipelineState: MTLRenderPipelineState
  let shadowPipelineState: MTLRenderPipelineState

  let morphTargetCount: Int
  let textureCount: Int

  let vertexBuffer: MTLBuffer
  let submesh: MTKSubmesh?

  var vertexCount: Int
  var transform = Transform()
  let name: String

  static let mdlVertexDescriptor: MDLVertexDescriptor = {
    let vertexDescriptor = MDLVertexDescriptor()
    var offset = 0
    let packedFloat3Size = MemoryLayout<Float>.stride * 3
    vertexDescriptor.attributes[Int(Position.rawValue)] =
      MDLVertexAttribute(
        name: MDLVertexAttributePosition,
        format: .float3,
        offset: offset,
        bufferIndex: 0)
    offset += packedFloat3Size
    vertexDescriptor.attributes[Int(Normal.rawValue)] =
      MDLVertexAttribute(
        name: MDLVertexAttributeNormal,
        format: .float3,
        offset: offset,
        bufferIndex: 0)
    offset += packedFloat3Size
    vertexDescriptor.attributes[Int(UV.rawValue)] =
      MDLVertexAttribute(
        name: MDLVertexAttributeTextureCoordinate,
        format: .float2,
        offset: offset,
        bufferIndex: 0)
    offset += MemoryLayout<float2>.stride
    vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: offset)
    return vertexDescriptor
  }()

  static let mtlVertexDescriptor: MTLVertexDescriptor = {
    return MTKMetalVertexDescriptorFromModelIO(Nature.mdlVertexDescriptor)!
  }()

  let baseColorTexture: MTLTexture?

  init(
    name: String,
    instanceCount: Int = 1,
    textureNames: [String] = [],
    morphTargetNames: [String] = []
  ) {
    self.name = name
    morphTargetCount = morphTargetNames.count
    textureCount = textureNames.count

    // load up the first morph target into a buffer
    // assume only one vertex buffer and one material submesh for simplicity
    guard let mesh = Nature.loadMesh(name: morphTargetNames[0]) else {
      fatalError("morph target not loaded")
    }
    submesh = Nature.loadSubmesh(mesh: mesh)
    let bufferLength = mesh.vertexBuffers[0].buffer.length
    vertexBuffer =
      Renderer.device.makeBuffer(length: bufferLength * morphTargetNames.count)!
    vertexBuffer.label = "\(name) vertex buffer"
    let layout = mesh.vertexDescriptor.layouts[0] as! MDLVertexBufferLayout
    vertexCount = bufferLength / layout.stride

    let commandBuffer = Renderer.commandQueue.makeCommandBuffer()
    let blitEncoder = commandBuffer?.makeBlitCommandEncoder()
    for index in 0..<morphTargetNames.count {
      guard let mesh = Nature.loadMesh(name: morphTargetNames[index]) else {
        fatalError("morph target not loaded")
      }
      let buffer = mesh.vertexBuffers[0].buffer
      blitEncoder?.copy(
        from: buffer,
        sourceOffset: 0,
        to: vertexBuffer,
        destinationOffset: buffer.length * index,
        size: buffer.length)
    }
    blitEncoder?.endEncoding()
    commandBuffer?.commit()

    pipelineState = PipelineStates.createNaturePSO()
    shadowPipelineState = PipelineStates.createNatureShadowPSO()
    // load the instances
    self.instanceCount = instanceCount
    instanceBuffer = Nature.buildInstanceBuffer(instanceCount: instanceCount)

    // load the texture
    baseColorTexture =
      TextureController.loadTextureArray(textureNames: textureNames)

    modelTransformBuffers = (0..<maxFramesInFlight).map { _ in
      Renderer.device.makeBuffer(length: MemoryLayout<ModelTransform>.stride)!
    }
    // initialize the instance buffer in case there is only one instance
    // (there is no array of Transforms in this class)
    updateBuffer(
      instance: 0,
      transform: Transform(),
      textureID: 0,
      morphTargetID: 0)
  }

  static func loadSubmesh(mesh: MTKMesh) -> MTKSubmesh {
    guard let submesh = mesh.submeshes.first else {
      fatalError("No submesh found")
    }
    return submesh
  }

  static func buildInstanceBuffer(instanceCount: Int) -> MTLBuffer {
    guard let instanceBuffer =
      Renderer.device.makeBuffer(
        length: MemoryLayout<NatureInstance>.stride * instanceCount,
        options: []) else {
        fatalError("Failed to create instance buffer")
    }
    instanceBuffer.label = "Instance Buffer"
    return instanceBuffer
  }

  func updateBuffer(
    instance: Int,
    transform: Transform,
    textureID: Int,
    morphTargetID: Int
  ) {
    guard textureID < textureCount && morphTargetID < morphTargetCount else {
      fatalError("ID is too high")
    }
    var pointer = instanceBuffer.contents().bindMemory(
      to: NatureInstance.self,
      capacity: instanceCount)
    pointer = pointer.advanced(by: instance)
    pointer.pointee.modelMatrix = transform.modelMatrix
    pointer.pointee.normalMatrix = transform.modelMatrix.upperLeft
    pointer.pointee.textureID = UInt32(textureID)
    pointer.pointee.morphTargetID = UInt32(morphTargetID)
  }

  static func loadMesh(name: String) -> MTKMesh? {
    let assetURL = Bundle.main.url(forResource: name, withExtension: "usdz")!
    let allocator = MTKMeshBufferAllocator(device: Renderer.device)
    let asset = MDLAsset(
      url: assetURL,
      vertexDescriptor: mdlVertexDescriptor,
      bufferAllocator: allocator)
    let mdlMeshes = asset.childObjects(of: MDLMesh.self) as? [MDLMesh] ?? []
    guard let mdlMesh = mdlMeshes.first else { return nil }
    return try? MTKMesh(mesh: mdlMesh, device: Renderer.device)
  }

  func render(
    encoder: MTLRenderCommandEncoder,
    uniformsBuffer: MTLBuffer,
    params: Params,
    renderState: RenderState = .mainPass
  ) {
    guard let submesh = submesh else { return }
    var params = params
    let index = Renderer.currentFrameIndex
    let pointer = modelTransformBuffers[index]
      .contents().bindMemory(to: ModelTransform.self, capacity: 1)
    pointer.pointee.modelMatrix = transform.modelMatrix
    pointer.pointee.normalMatrix = float3x3(normalFrom4x4: transform.modelMatrix)
    encoder.setVertexBuffer(
      modelTransformBuffers[index], offset: 0, index: ModelTransformBuffer.index)
    let pipelineState = renderState == .mainPass ?
      pipelineState : shadowPipelineState
    encoder.setRenderPipelineState(pipelineState)
    encoder.setVertexBuffer(
      instanceBuffer,
      offset: 0,
      index: InstancesBuffer.index)

    // set vertex buffer
    encoder.setVertexBytes(
      &vertexCount,
      length: MemoryLayout<Int>.stride,
      index: 1)
    encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

    if renderState != .shadowPass {
      encoder.setFragmentBytes(
        &params,
        length: MemoryLayout<Params>.stride,
        index: ParamsBuffer.index)
      encoder.setFragmentTexture(baseColorTexture, index: 0)
    }
    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: submesh.indexCount,
      indexType: submesh.indexType,
      indexBuffer: submesh.indexBuffer.buffer,
      indexBufferOffset: submesh.indexBuffer.offset,
      instanceCount: instanceCount)
  }
}
// swiftlint:enable force_unwrapping
// swiftlint:enable force_cast
