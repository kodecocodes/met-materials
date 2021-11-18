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

class Renderer: NSObject {
  
  static var device: MTLDevice!
  static var commandQueue: MTLCommandQueue!
  static var colorPixelFormat: MTLPixelFormat!
  static var library: MTLLibrary!
  
  var renderPipelineState: MTLRenderPipelineState!
  var depthStencilState: MTLDepthStencilState!
  
  var uniforms = Uniforms()
  var fragmentUniforms = FragmentUniforms()
  
  lazy var camera: Camera = {
    let camera = Camera()
    camera.position = [0, 0.4, -5]
    camera.rotation = [-0.3, -0.1, 0]
    return camera
  }()
  
  lazy var sunlight: Light = {
    var light = buildDefaultLight()
    light.position = [1, 2, -2]
    light.intensity = 1.5
    return light
  }()
  
  var lights = [Light]()
  var models: [Model] = []
  
  init(metalView: MTKView) {
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("GPU not available")
    }
    metalView.device = device
    Renderer.device = device
    Renderer.commandQueue = device.makeCommandQueue()!
    Renderer.colorPixelFormat = metalView.colorPixelFormat
    Renderer.library = device.makeDefaultLibrary()
    
    super.init()
    metalView.clearColor = MTLClearColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1)
    metalView.depthStencilPixelFormat = .depth32Float
    metalView.delegate = self
    
    lights.append(sunlight)
    fragmentUniforms.lightCount = UInt32(lights.count)
    
    let train = Model(name: "train")
    train.position = [-0.5, 0, 0]
    train.rotation = [0, Float(45).degreesToRadians, 0]
    models.append(train)
    
    let tree = Model(name: "treefir")
    tree.position = [1.4, 0, 3]
    tree.position = [1.4, 0, 0]
    models.append(tree)
    
    let plane = Model(name: "plane")
    plane.scale = [8, 8, 8]
    plane.position = [0, 0, 0]
    models.append(plane)
    
    // create texture here
    
    buildPipelineStates()
    buildDepthStencilState()

    mtkView(metalView, drawableSizeWillChange: metalView.drawableSize)
  }
  
  func createTexture(pixelFormat: MTLPixelFormat, size: CGSize) -> MTLTexture {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat,
                                                              width: Int(size.width),
                                                              height: Int(size.height),
                                                              mipmapped: false)
    descriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
    descriptor.storageMode = .private
    guard let texture = Renderer.device.makeTexture(descriptor: descriptor) else { fatalError() }
    return texture
  }

  
  func buildPipelineStates() {
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = Renderer.library.makeFunction(name: "vertex_main")
    pipelineDescriptor.fragmentFunction = Renderer.library.makeFunction(name: "fragment_main")
    pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(Model.defaultVertexDescriptor)
    pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.colorPixelFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    do {
      renderPipelineState = try Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
  }
  
  func buildDepthStencilState() {
    let descriptor = MTLDepthStencilDescriptor()
    descriptor.depthCompareFunction = .less
    descriptor.isDepthWriteEnabled = true
    depthStencilState = Renderer.device.makeDepthStencilState(descriptor: descriptor)
  }
  
  func buildDefaultLight() -> Light {
    var light = Light()
    light.position = [0, 0, 0]
    light.color = [1, 1, 1]
    light.intensity = 1
    light.attenuation = float3(1, 0, 0)
    light.type = Sunlight
    return light
  }
}

extension Renderer: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    camera.aspect = Float(view.bounds.width)/Float(view.bounds.height)
    uniforms.projectionMatrix = camera.projectionMatrix
  }
  
  func draw(in view: MTKView) {
    guard let descriptor = view.currentRenderPassDescriptor,
          let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
          let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
          let drawable = view.currentDrawable else {
      return
    }
    
    renderEncoder.pushDebugGroup("Render encoder")
    uniforms.viewMatrix = camera.viewMatrix
    fragmentUniforms.cameraPosition = camera.position
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setFragmentBytes(&lights,
                                   length: MemoryLayout<Light>.stride * lights.count,
                                   index: 2)
    renderEncoder.setFragmentBytes(&fragmentUniforms,
                                   length: MemoryLayout<FragmentUniforms>.stride,
                                   index: 3)
    renderEncoder.setRenderPipelineState(renderPipelineState)
    
    for model in models {
      uniforms.modelMatrix = model.modelMatrix
      uniforms.normalMatrix = float3x3(normalFrom4x4: model.modelMatrix)
      renderEncoder.setVertexBytes(&uniforms,
                                   length: MemoryLayout<Uniforms>.stride, index: 1)
      renderEncoder.setVertexBuffer(model.vertexBuffer, offset: 0, index: 0)
      
      for modelSubmesh in model.submeshes {
        let submesh = modelSubmesh.submesh
        renderEncoder.setFragmentBytes(&modelSubmesh.material,
                                       length: MemoryLayout<Material>.stride,
                                       index: 1)
        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: submesh.indexCount,
                                            indexType: submesh.indexType,
                                            indexBuffer: submesh.indexBuffer.buffer,
                                            indexBufferOffset: submesh.indexBuffer.offset)
      }
    }
    renderEncoder.endEncoding()
    renderEncoder.popDebugGroup()
    
    // MPS brightness filter
    
    
    // MPS blur filter
    
    
    // blit encoder
    
    
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
