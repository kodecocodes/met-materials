/**
 * Copyright (c) 2019 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */


import MetalKit

class Nature: Node {
  let instanceCount: Int
  let instanceBuffer: MTLBuffer
  let pipelineState: MTLRenderPipelineState
  
  let morphTargetCount: Int
  let textureCount: Int

  let vertexBuffer: MTLBuffer
  let submesh: MTKSubmesh?
  
  var vertexCount: Int
  
  static let mdlVertexDescriptor: MDLVertexDescriptor = {
    let vertexDescriptor = MDLVertexDescriptor()
    var offset = 0
    let packedFloat3Size = MemoryLayout<Float>.stride * 3
    vertexDescriptor.attributes[Int(Position.rawValue)] =
      MDLVertexAttribute(name: MDLVertexAttributePosition,
                         format: .float3,
                         offset: offset, bufferIndex: 0)
    offset += packedFloat3Size
    vertexDescriptor.attributes[Int(Normal.rawValue)] =
      MDLVertexAttribute(name: MDLVertexAttributeNormal,
                         format: .float3,
                         offset: offset, bufferIndex: 0)
    offset += packedFloat3Size
    vertexDescriptor.attributes[Int(UV.rawValue)] =
      MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
                         format: .float2,
                         offset: offset, bufferIndex: 0)
    offset += MemoryLayout<float2>.stride
    vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: offset)
    return vertexDescriptor
  }()
  
  static let mtlVertexDescriptor: MTLVertexDescriptor = {
    return MTKMetalVertexDescriptorFromModelIO(Nature.mdlVertexDescriptor)!
  }()
  
  let baseColorTexture: MTLTexture?
  
  init(name: String,
       instanceCount: Int = 1,
       textureNames: [String] = [],
       morphTargetNames: [String] = []
    ) {
    
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
    let layout = mesh.vertexDescriptor.layouts[0] as! MDLVertexBufferLayout
    vertexCount = bufferLength / layout.stride
    
    let commandBuffer = Renderer.commandQueue.makeCommandBuffer()
    let blitEncoder = commandBuffer?.makeBlitCommandEncoder()
    for i in 0..<morphTargetNames.count {
      guard let mesh = Nature.loadMesh(name: morphTargetNames[i]) else {
        fatalError("morph target not loaded")
      }
      let buffer = mesh.vertexBuffers[0].buffer
      blitEncoder?.copy(from: buffer, sourceOffset: 0,
                        to: vertexBuffer,
                        destinationOffset: buffer.length * i,
                        size: buffer.length)
    }
    blitEncoder?.endEncoding()
    commandBuffer?.commit()
    
    // create the pipeline state
    let library = Renderer.library
    guard let vertexFunction = library?.makeFunction(name: "vertex_nature"),
      let fragmentFunction = library?.makeFunction(name: "fragment_nature") else {
        fatalError("failed to create functions")
    }
    pipelineState = Nature.makePipelineState(vertex: vertexFunction,
                                            fragment: fragmentFunction)

    // load the instances
    self.instanceCount = instanceCount
    instanceBuffer = Nature.buildInstanceBuffer(instanceCount: instanceCount)
    
    // load the texture
    baseColorTexture =
      Nature.loadTextureArray(textureNames: textureNames)
    super.init()
    
    // initialize the instance buffer in case there is only one instance
    // (there is no array of Transforms in this class)
    updateBuffer(instance: 0, transform: Transform(),
                 textureID: 0, morphTargetID: 0)
    self.name = name
  }
  
  static func loadSubmesh(mesh: MTKMesh) -> MTKSubmesh {
    guard let submesh = mesh.submeshes.first else {
      fatalError("No submesh found")
    }
    return submesh
  }
  
  static func buildInstanceBuffer(instanceCount: Int) -> MTLBuffer {
    guard let instanceBuffer =
      Renderer.device.makeBuffer(length: MemoryLayout<NatureInstance>.stride * instanceCount,
                                 options: []) else {
        fatalError("Failed to create instance buffer")
    }
    return instanceBuffer
  }
  
  func updateBuffer(instance: Int, transform: Transform,
                    textureID: Int, morphTargetID: Int) {
    guard textureID < textureCount && morphTargetID < morphTargetCount else {
      fatalError("ID is too high")
    }
    var pointer =
      instanceBuffer.contents().bindMemory(to: NatureInstance.self,
                                           capacity: instanceCount)
    pointer = pointer.advanced(by: instance)
    pointer.pointee.modelMatrix = transform.modelMatrix
    pointer.pointee.normalMatrix = transform.normalMatrix
    pointer.pointee.textureID = UInt32(textureID)
    pointer.pointee.morphTargetID = UInt32(morphTargetID)
  }
  
  static func loadMesh(name: String) -> MTKMesh? {
    let assetURL = Bundle.main.url(forResource: name, withExtension: "obj")!
    let allocator = MTKMeshBufferAllocator(device: Renderer.device)
    let asset = MDLAsset(url: assetURL,
                         vertexDescriptor: mdlVertexDescriptor,
                         bufferAllocator: allocator)
    let mdlMesh = asset.object(at: 0) as! MDLMesh
    return try? MTKMesh(mesh: mdlMesh, device: Renderer.device)
  }
  
  static func makePipelineState(vertex: MTLFunction,
                                fragment: MTLFunction) -> MTLRenderPipelineState {
    
    var pipelineState: MTLRenderPipelineState
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertex
    pipelineDescriptor.fragmentFunction = fragment
    
    pipelineDescriptor.vertexDescriptor = Nature.mtlVertexDescriptor
    pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.colorPixelFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    do {
      pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
    return pipelineState
  }
}


extension Nature: Texturable {}

extension Nature: Renderable {
  func render(renderEncoder: MTLRenderCommandEncoder, uniforms vertex: Uniforms, fragmentUniforms fragment: FragmentUniforms) {
    guard let submesh = submesh else { return }
    var uniforms = vertex
    var fragmentUniforms = fragment
    uniforms.modelMatrix = worldTransform
    uniforms.normalMatrix = float3x3(normalFrom4x4: modelMatrix)

    renderEncoder.setRenderPipelineState(pipelineState)

    renderEncoder.setVertexBytes(&uniforms,
                                 length: MemoryLayout<Uniforms>.stride,
                                 index: Int(BufferIndexUniforms.rawValue))
    renderEncoder.setVertexBuffer(instanceBuffer, offset: 0,
                                  index: Int(BufferIndexInstances.rawValue))
    
    // set vertex buffer
    renderEncoder.setVertexBytes(&vertexCount,
                                 length: MemoryLayout<Int>.stride,
                                 index: 1)
    renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

    renderEncoder.setFragmentBytes(&fragmentUniforms,
                                   length: MemoryLayout<FragmentUniforms>.stride,
                                   index: Int(BufferIndexFragmentUniforms.rawValue))
    renderEncoder.setFragmentTexture(baseColorTexture, index: 0)
    renderEncoder.drawIndexedPrimitives(type: .triangle,
                                        indexCount: submesh.indexCount,
                                        indexType: submesh.indexType,
                                        indexBuffer: submesh.indexBuffer.buffer,
                                        indexBufferOffset: submesh.indexBuffer.offset,
                                        instanceCount:  instanceCount)
  }
}
