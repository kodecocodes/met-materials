/**
 * Copyright (c) 2018 Razeware LLC
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

public class Renderer: NSObject {
  
  let device: MTLDevice
  let commandQueue: MTLCommandQueue
  var pipelineState: MTLRenderPipelineState!
  var depthStencilState: MTLDepthStencilState!
  var texture: MTLTexture?
  var terrainTexture: MTLTexture?
  
  let camera = Camera()

  lazy var model: MTKMesh = {
    do {
      let primitive = self.loadModel(name: "tree")!
      let model = try MTKMesh(mesh: primitive,
                              device: device)
      texture = loadTexture(imageName: "treeColor")
      return model
    } catch {
      fatalError()
    }
  }()
  var modelTransform = Transform()
  
  lazy var terrain: MTKMesh = {
    do {
      let primitive = self.loadModel(name: "plane")!
      let model = try MTKMesh(mesh: primitive,
                              device: device)
      terrainTexture = loadTexture(imageName: "planeColor")
      return model
    } catch {
      fatalError()
    }
  }()
  var terrainTransform = Transform()

  public init(metalView: MTKView) {
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("GPU not available")
    }
    metalView.device = device
    self.device = device
    commandQueue = device.makeCommandQueue()!
    super.init()
    metalView.clearColor = MTLClearColor(red: 1,
                                         green: 1,
                                         blue: 0.8,
                                         alpha: 1)
    metalView.depthStencilPixelFormat = .depth32Float
    metalView.delegate = self

    buildPipelineState()
    buildDepthStencilState()
    
    camera.transform.position = [0, 2.5, -1]
    modelTransform.position = [0, 0, 6]
    terrainTransform.scale = [50, 50, 50]
  }
  
  func loadModel(name: String) -> MDLMesh? {
    guard let assetURL = Bundle.main.url(forResource: name, withExtension: "obj")
      else { fatalError("Model not found") }
    
    let vertexDescriptor = MTLVertexDescriptor()
    
    var offset = 0
    vertexDescriptor.attributes[0].format = .float3
    vertexDescriptor.attributes[0].offset = 0
    vertexDescriptor.attributes[0].bufferIndex = 0
    offset += MemoryLayout<float3>.stride
    
    vertexDescriptor.attributes[1].format = .float3
    vertexDescriptor.attributes[1].offset = offset
    vertexDescriptor.attributes[1].bufferIndex = 0
    offset += MemoryLayout<float3>.stride
    
    vertexDescriptor.attributes[2].format = .float2
    vertexDescriptor.attributes[2].offset = offset
    vertexDescriptor.attributes[2].bufferIndex = 0
    offset += MemoryLayout<float3>.stride
    
    vertexDescriptor.layouts[0].stride = offset
    
    let descriptor = MTKModelIOVertexDescriptorFromMetal(vertexDescriptor)
    
    (descriptor.attributes[0] as! MDLVertexAttribute).name = MDLVertexAttributePosition
    (descriptor.attributes[1] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
    (descriptor.attributes[2] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
    
    let bufferAllocator = MTKMeshBufferAllocator(device: device)
    let asset = MDLAsset(url: assetURL,
                         vertexDescriptor: descriptor,
                         bufferAllocator: bufferAllocator)
    let mesh = asset.object(at: 0) as! MDLMesh
    return mesh
  }
  
  func buildPipelineState() {
    do {
      guard let path = Bundle.main.path(forResource: "Shaders", ofType: "metal") else { return }
      let source = try String(contentsOfFile: path, encoding: .utf8)
      let library = try device.makeLibrary(source: source, options: nil)
      let vertexFunction = library.makeFunction(name: "vertex_main")
      let fragmentFunction = library.makeFunction(name: "fragment_main")
      let descriptor = MTLRenderPipelineDescriptor()
      descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
      descriptor.depthAttachmentPixelFormat = .depth32Float
      descriptor.vertexFunction = vertexFunction
      descriptor.fragmentFunction = fragmentFunction
      descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(model.vertexDescriptor)
      pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
  }

  func buildDepthStencilState() {
    let descriptor = MTLDepthStencilDescriptor()
    descriptor.depthCompareFunction = .less
    descriptor.isDepthWriteEnabled = true
    depthStencilState = device.makeDepthStencilState(descriptor: descriptor)
  }
  
  func loadTexture(imageName: String) -> MTLTexture? {
    guard let url = Bundle.main.url(forResource: imageName, withExtension: "png")
    else {return nil}
    
    let textureLoader = MTKTextureLoader(device: device)
    let textureLoaderOptions: [MTKTextureLoader.Option: Any]
    textureLoaderOptions = [.origin: MTKTextureLoader.Origin.bottomLeft,
                            .SRGB: false]
    return try? textureLoader.newTexture(URL: url, options: textureLoaderOptions)
  }
  
  public func zoomUsing(delta: CGFloat) {
    let sensitivity = Float(0.1)
    let rotation = camera.transform.rotation
    let dx = Float(delta) * sensitivity * sin(rotation.y)
    let dz = Float(delta) * sensitivity * cos(rotation.y)
    camera.transform.position.x -= dx
    camera.transform.position.z += dz
  }
  
  public func rotateUsing(translation: NSPoint) {
    let sensitivity: Float = 0.01
    camera.transform.rotation.x -= Float(translation.y) * sensitivity
    camera.transform.rotation.y += Float(translation.x) * sensitivity
  }
}

extension Renderer: MTKViewDelegate {
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    camera.aspect = Float(size.width/size.height)
  }
  
  public func draw(in view: MTKView) {
    guard let descriptor = view.currentRenderPassDescriptor,
          let commandBuffer = commandQueue.makeCommandBuffer(),
          let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
          let drawable = view.currentDrawable else {
      return
    }
    renderEncoder.setCullMode(.none)
    renderEncoder.setDepthStencilState(depthStencilState)
    
    // render terrain
    renderEncoder.setRenderPipelineState(pipelineState)
    var modelViewProjectionMatrix = camera.projectionMatrix * camera.viewMatrix * terrainTransform.matrix
    renderEncoder.setVertexBytes(&modelViewProjectionMatrix, length: MemoryLayout<float4x4>.stride, index: 1)
    renderEncoder.setVertexBuffer(terrain.vertexBuffers[0].buffer, offset: 0, index: 0)
    renderEncoder.setFragmentTexture(terrainTexture, index: 0)
    draw(renderEncoder: renderEncoder, model: terrain)
    
    // render tree
    modelViewProjectionMatrix = camera.projectionMatrix * camera.viewMatrix * modelTransform.matrix
    renderEncoder.setVertexBytes(&modelViewProjectionMatrix, length: MemoryLayout<float4x4>.stride, index: 1)
    renderEncoder.setVertexBuffer(model.vertexBuffers[0].buffer, offset: 0, index: 0)
    renderEncoder.setFragmentTexture(texture, index: 0)
    draw(renderEncoder: renderEncoder, model: model)
    
    renderEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
  
  func draw(renderEncoder: MTLRenderCommandEncoder, model: MTKMesh) {
    for submesh in model.submeshes {
      renderEncoder.drawIndexedPrimitives(type: .triangle,
                                          indexCount: submesh.indexCount,
                                          indexType: submesh.indexType,
                                          indexBuffer: submesh.indexBuffer.buffer,
                                          indexBufferOffset: submesh.indexBuffer.offset)
    }

  }
}
