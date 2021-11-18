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

class Renderer: NSObject {
  
  static var device: MTLDevice!
  static var commandQueue: MTLCommandQueue!
  static var colorPixelFormat: MTLPixelFormat!
  static var library: MTLLibrary!
  
  var renderPipelineState: MTLRenderPipelineState!
  var depthStencilState: MTLDepthStencilState!
  
  var uniforms = Uniforms()
  var fragmentUniforms = FragmentUniforms()
  
  var albedoTexture: MTLTexture!
  var normalTexture: MTLTexture!
  var positionTexture: MTLTexture!
  var depthTexture: MTLTexture!
  
  var gBufferPipelineState: MTLRenderPipelineState!
  var gBufferRenderPassDescriptor: MTLRenderPassDescriptor!
  var lightsBuffer: MTLBuffer!
  
  lazy var camera: Camera = {
    let camera = Camera()
    camera.position = [0, 0, -5]
    camera.rotation = [-0.5, -0.5, 0]
    return camera
  }()
  
  lazy var sunlight: Light = {
    var light = buildDefaultLight()
    light.position = [1, 2, -2]
    light.intensity = 0.8
    return light
  }()
  
  var shadowTexture: MTLTexture!
  let shadowRenderPassDescriptor = MTLRenderPassDescriptor()
  var shadowPipelineState: MTLRenderPipelineState!
  
  var lights = [Light]()
  var models: [Model] = []
  
  var compositionPipelineState: MTLRenderPipelineState!
  
  var quadVerticesBuffer: MTLBuffer!
  var quadTexCoordsBuffer: MTLBuffer!
  
  let quadVertices: [Float] = [
    -1.0,  1.0,
    1.0, -1.0,
    -1.0, -1.0,
    -1.0,  1.0,
    1.0,  1.0,
    1.0, -1.0,
  ]
  
  let quadTexCoords: [Float] = [
    0.0, 0.0,
    1.0, 1.0,
    0.0, 1.0,
    0.0, 0.0,
    1.0, 0.0,
    1.0, 1.0
  ]
  
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
    metalView.clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 0.8, alpha: 1)
    metalView.depthStencilPixelFormat = .depth32Float
    metalView.delegate = self
    mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
    metalView.framebufferOnly = false
    
    lights.append(sunlight)
    createPointLights(count: 300, min: [-10, 0.3, -10], max: [10, 2, 20])
    
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
    
    buildRenderPipelineState()
    buildDepthStencilState()
    buildShadowTexture(size: metalView.drawableSize)
    buildShadowPipelineState()
    buildGbufferPipelineState()
    
    quadVerticesBuffer = Renderer.device.makeBuffer(bytes: quadVertices,
                                                    length: MemoryLayout<Float>.size * quadVertices.count, options: [])
    quadVerticesBuffer.label = "Quad vertices"
    quadTexCoordsBuffer = Renderer.device.makeBuffer(bytes: quadTexCoords,
                                                     length: MemoryLayout<Float>.size * quadTexCoords.count, options: [])
    quadTexCoordsBuffer.label = "Quad texCoords"
    
    buildCompositionPipelineState()
    
    lightsBuffer = Renderer.device.makeBuffer(bytes: lights,
                                              length: MemoryLayout<Light>.stride * lights.count, options: [])
  }
  
  func buildGbufferTextures(size: CGSize) {
    albedoTexture = buildTexture(pixelFormat: .bgra8Unorm,
                                 size: size, label: "Albedo texture")
    normalTexture = buildTexture(pixelFormat: .rgba16Float,
                                 size: size, label: "Normal texture")
    positionTexture = buildTexture(pixelFormat: .rgba16Float,
                                   size: size, label: "Position texture")
    depthTexture = buildTexture(pixelFormat: .depth32Float,
                                size: size, label: "Depth texture")
  }
  
  func buildGBufferRenderPassDescriptor(size: CGSize) {
    gBufferRenderPassDescriptor = MTLRenderPassDescriptor()
    buildGbufferTextures(size: size)
    let textures: [MTLTexture] = [albedoTexture,
                                  normalTexture,
                                  positionTexture]
    for (position, texture) in textures.enumerated() {
      gBufferRenderPassDescriptor.setUpColorAttachment(position: position,
                                                       texture: texture)
    }
    gBufferRenderPassDescriptor.setUpDepthAttachment(texture: depthTexture)
  }
  
  func buildShadowPipelineState() {
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = Renderer.library.makeFunction(
      name: "vertex_depth")
    pipelineDescriptor.fragmentFunction = nil
    pipelineDescriptor.colorAttachments[0].pixelFormat = .invalid
    pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(Model.defaultVertexDescriptor)
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    do {
      shadowPipelineState = try Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
  }
  
  func buildRenderPipelineState() {
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
  
  func buildGbufferPipelineState() {
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    descriptor.colorAttachments[1].pixelFormat = .rgba16Float
    descriptor.colorAttachments[2].pixelFormat = .rgba16Float
    descriptor.depthAttachmentPixelFormat = .depth32Float
    descriptor.label = "GBuffer state"
    
    descriptor.vertexFunction =
      Renderer.library.makeFunction(name: "vertex_main")
    descriptor.fragmentFunction =
      Renderer.library.makeFunction(name: "gBufferFragment")
    descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(Model.defaultVertexDescriptor)
    do {
      gBufferPipelineState = try Renderer.device.makeRenderPipelineState(descriptor: descriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
  }
  
  func buildCompositionPipelineState() {
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.colorAttachments[0].pixelFormat = Renderer.colorPixelFormat
    descriptor.depthAttachmentPixelFormat = .depth32Float
    descriptor.label = "Composition state"
    descriptor.vertexFunction = Renderer.library.makeFunction(
      name: "compositionVert")
    descriptor.fragmentFunction = Renderer.library.makeFunction(
      name: "compositionFrag")
    do {
      compositionPipelineState =
        try Renderer.device.makeRenderPipelineState(descriptor: descriptor)
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
  
  func buildTexture(pixelFormat: MTLPixelFormat, size: CGSize, label: String) -> MTLTexture {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: pixelFormat,
      width: Int(size.width),
      height: Int(size.height),
      mipmapped: false)
    descriptor.usage = [.shaderRead, .renderTarget]
    descriptor.storageMode = .private
    guard let texture =
      Renderer.device.makeTexture(descriptor: descriptor) else {
        fatalError()
    }
    texture.label = "\(label) texture"
    return texture
  }
  
  func buildShadowTexture(size: CGSize) {
    shadowTexture = buildTexture(pixelFormat: .depth32Float,
                                 size: size, label: "Shadow")
    shadowRenderPassDescriptor.setUpDepthAttachment(texture: shadowTexture)
  }
  
  
  func renderShadowPass(renderEncoder: MTLRenderCommandEncoder) {
    renderEncoder.pushDebugGroup("Shadow pass")
    renderEncoder.label = "Shadow encoder"
    renderEncoder.setCullMode(.none)
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setDepthBias(0.01, slopeScale: 1.0, clamp: 0.01)

    uniforms.projectionMatrix = float4x4(orthoLeft: -8, right: 8,
                                         bottom: -8, top: 8,
                                         near: 0.1, far: 16)
    let position: float3 = [sunlight.position.x,
                            sunlight.position.y,
                            sunlight.position.z]
    let center: float3 = [0, 0, 0]
    let lookAt = float4x4(eye: position, center: center, up: [0,1,0])
    uniforms.viewMatrix = lookAt
    uniforms.shadowMatrix = uniforms.projectionMatrix * uniforms.viewMatrix
    
    renderEncoder.setRenderPipelineState(shadowPipelineState)
    for model in models {
      draw(renderEncoder: renderEncoder, model: model)
    }
    renderEncoder.endEncoding()
    renderEncoder.popDebugGroup()
  }
  
  func renderCompositionPass(renderEncoder: MTLRenderCommandEncoder) {
    renderEncoder.pushDebugGroup("Composition pass")
    renderEncoder.label = "Composition encoder"
    renderEncoder.setRenderPipelineState(compositionPipelineState)
    renderEncoder.setDepthStencilState(depthStencilState)
    // 1
    renderEncoder.setVertexBuffer(quadVerticesBuffer, offset: 0, index: 0)
    renderEncoder.setVertexBuffer(quadTexCoordsBuffer, offset: 0, index: 1)
    // 2
    renderEncoder.setFragmentTexture(albedoTexture, index: 0)
    renderEncoder.setFragmentTexture(normalTexture, index: 1)
    renderEncoder.setFragmentTexture(positionTexture, index: 2)
    renderEncoder.setFragmentBuffer(lightsBuffer, offset: 0, index: 2)
    renderEncoder.setFragmentBytes(&fragmentUniforms,
                                   length: MemoryLayout<FragmentUniforms>.stride, index: 3)
    // 3
    renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0,
                                 vertexCount: quadVertices.count)
    renderEncoder.endEncoding()
    renderEncoder.popDebugGroup()
  }
}

extension Renderer: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    camera.aspect = Float(view.bounds.width)/Float(view.bounds.height)
    uniforms.projectionMatrix = camera.projectionMatrix
    buildShadowTexture(size: size)
    buildGBufferRenderPassDescriptor(size: size)
  }
  
  func draw(in view: MTKView) {
    guard let descriptor = view.currentRenderPassDescriptor,
      let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
      let drawable = view.currentDrawable else {
        return
    }
    
    models[0].rotation.y += 0.01
    
    // shadow pass
    guard let shadowEncoder = commandBuffer.makeRenderCommandEncoder(
      descriptor: shadowRenderPassDescriptor) else {
        return
    }
    renderShadowPass(renderEncoder: shadowEncoder)
    
    // main pass
    /*
    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
      return
    }
    renderEncoder.pushDebugGroup("Main pass")
    renderEncoder.label = "Main encoder"
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
    uniforms.projectionMatrix = camera.projectionMatrix
    
    renderEncoder.setFragmentTexture(shadowTexture, index: 0)
    
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
     */

    // g-buffer pass
    guard let gBufferEncoder = commandBuffer.makeRenderCommandEncoder(
      descriptor: gBufferRenderPassDescriptor) else {
        return
    }
    renderGbufferPass(renderEncoder: gBufferEncoder)
    
    // blit
    /*
    guard let blitEncoder = commandBuffer.makeBlitCommandEncoder() else {
      return
    }
    blitEncoder.pushDebugGroup("Blit")
    blitEncoder.label = "Blit encoder"
    let origin = MTLOriginMake(0, 0, 0)
    let size = MTLSizeMake(Int(view.drawableSize.width), Int(view.drawableSize.height), 1)
    blitEncoder.copy(from: albedoTexture, sourceSlice: 0, sourceLevel: 0,
                     sourceOrigin: origin, sourceSize: size,
                     to: drawable.texture, destinationSlice: 0,
                     destinationLevel: 0, destinationOrigin: origin)
    blitEncoder.endEncoding()
    blitEncoder.popDebugGroup()
     */

    // composition pass
    guard let compositionEncoder = commandBuffer.makeRenderCommandEncoder(
      descriptor: descriptor) else {
        return
    }
    renderCompositionPass(renderEncoder: compositionEncoder)
    
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
  
  func draw(renderEncoder: MTLRenderCommandEncoder, model: Model) {
    uniforms.modelMatrix = model.modelMatrix
    uniforms.normalMatrix = float3x3(normalFrom4x4: model.modelMatrix)
    renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
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
  
  func renderGbufferPass(renderEncoder: MTLRenderCommandEncoder) {
    renderEncoder.pushDebugGroup("Gbuffer pass")
    renderEncoder.label = "Gbuffer encoder"
    
    renderEncoder.setRenderPipelineState(gBufferPipelineState)
    renderEncoder.setDepthStencilState(depthStencilState)
    
    uniforms.viewMatrix = camera.viewMatrix
    uniforms.projectionMatrix = camera.projectionMatrix
    fragmentUniforms.cameraPosition = camera.position
    renderEncoder.setFragmentTexture(shadowTexture, index: 0)
    renderEncoder.setFragmentBytes(&fragmentUniforms,
                                   length: MemoryLayout<FragmentUniforms>.stride,
                                   index: 3)
    for model in models {
      draw(renderEncoder: renderEncoder, model: model)
    }
    renderEncoder.endEncoding()
    renderEncoder.popDebugGroup()
  }
}


private extension MTLRenderPassDescriptor {
  func setUpDepthAttachment(texture: MTLTexture) {
    depthAttachment.texture = texture
    depthAttachment.loadAction = .clear
    depthAttachment.storeAction = .store
    depthAttachment.clearDepth = 1
  }
  
  func setUpColorAttachment(position: Int, texture: MTLTexture) {
    let attachment: MTLRenderPassColorAttachmentDescriptor = colorAttachments[position]
    attachment.texture = texture
    attachment.loadAction = .clear
    attachment.storeAction = .store
    attachment.clearColor = MTLClearColorMake(0.73, 0.92, 1, 1)
  }
}

