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
  let commandQueue: MTLCommandQueue!
  var pipelineState: MTLRenderPipelineState!
  var depthStencilState: MTLDepthStencilState!
  var defaultSamplerState: MTLSamplerState?
  var timer: Float = 0
  
  let camera = Camera()
  let reflectionCamera = Camera()
  
  lazy var model: MTKMesh = {
    let model = self.loadModel(name: "house")
    modelTexture = try! Renderer.loadTexture(imageName: "house-color.png")
    return model
  }()
  
  var modelTransform = Transform()
  var modelTexture: MTLTexture?
  var uniforms = Uniforms()
  
  lazy var skybox: MTKMesh = {
    do {
      let allocator = MTKMeshBufferAllocator(device: Renderer.device)
      let newCube = MDLMesh(boxWithExtent: [1,1,1], segments: [1, 1, 1],
                            inwardNormals: true, geometryType: .triangles,
                            allocator: allocator)
      let model = try MTKMesh(mesh: newCube, device: Renderer.device)
      return model
    } catch {
      fatalError("failed to create skybox mesh")
    }
  }()
  
  var skyboxTexture: MTLTexture?
  var skyboxPipelineState: MTLRenderPipelineState!
  var skyboxTransform = Transform()
  
  lazy var terrain: MTKMesh = {
    let terrain = loadModel(name: "Terrain")
    terrainTexture = try! Renderer.loadTexture(imageName: "ground.png")
    return terrain
  }()
  
  var terrainTransform = Transform()
  var terrainTexture: MTLTexture?
  var terrainPipelineState: MTLRenderPipelineState!
  var underwaterTexture: MTLTexture
  
  lazy var water: MTKMesh = {
    do {
      let mesh = Primitive.plane(device: Renderer.device)
      let water = try MTKMesh(mesh: mesh, device: Renderer.device)
      waterTexture = try Renderer.loadTexture(imageName: "normal-water.png")
      return water
    } catch let error {
      fatalError(error.localizedDescription)
    }
  }()
  
  var waterTransform = Transform()
  var waterPipelineState: MTLRenderPipelineState!
  var waterTexture: MTLTexture?
  
  let reflectionRenderPass: RenderPass
  let refractionRenderPass: RenderPass
  
  init(metalView: MTKView) {
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("GPU not available")
    }
    metalView.device = device
    Renderer.device = device
    commandQueue = device.makeCommandQueue()!
    underwaterTexture = try! Renderer.loadTexture(imageName: "underwater.png")
    reflectionRenderPass = RenderPass(name: "reflection",
                                      size: metalView.drawableSize)
    refractionRenderPass = RenderPass(name: "refraction",
                                      size: metalView.drawableSize)
    super.init()
    metalView.clearColor = MTLClearColor(red: 1,
                                         green: 1,
                                         blue: 0.8,
                                         alpha: 1)
    metalView.depthStencilPixelFormat = .depth32Float
    metalView.delegate = self
    
    buildPipelineState()
    buildDepthStencilState()
    
    skyboxTexture = loadSkyboxTexture()
    mtkView(metalView, drawableSizeWillChange: metalView.drawableSize)
    
    // MARK:- Transforms
    camera.transform.position = [10, 2, 35]
    camera.transform.rotation = [-0.1, 3, 0]
    modelTransform.position = [0, 0.5, 5]
    modelTransform.rotation.y = 0.4
    modelTransform.scale = [2, 2, 2]
    terrainTransform.position = [0, 1, 0]
    terrainTransform.scale = [3,3,3]
  }
  
  func buildPipelineState() {
    guard let device = Renderer.device else {
      return
    }
    let vertexMain = "vertex_main"
    do {
      let library = device.makeDefaultLibrary()!
      let vertexFunction = library.makeFunction(name: vertexMain)
      let fragmentFunction = library.makeFunction(name: "fragment_main")
      let descriptor = MTLRenderPipelineDescriptor()
      descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
      descriptor.depthAttachmentPixelFormat = .depth32Float
      descriptor.vertexFunction = vertexFunction
      descriptor.fragmentFunction = fragmentFunction
      descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(model.vertexDescriptor)
      try pipelineState = device.makeRenderPipelineState(descriptor: descriptor)
      
      // skybox pipeline state
      descriptor.vertexFunction = library.makeFunction(name: "vertex_skybox")
      descriptor.fragmentFunction = library.makeFunction(name: "fragment_skybox")
      descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
      descriptor.depthAttachmentPixelFormat = .depth32Float
      descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(skybox.vertexDescriptor)
      try skyboxPipelineState = device.makeRenderPipelineState(descriptor: descriptor)
      
      // terrain pipeline state
      descriptor.vertexFunction = library.makeFunction(name: vertexMain)
      descriptor.fragmentFunction = library.makeFunction(name: "fragment_terrain")
      descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
      descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(terrain.vertexDescriptor)
      try terrainPipelineState = device.makeRenderPipelineState(descriptor: descriptor)
      
      guard let attachment = descriptor.colorAttachments[0] else { return }
      attachment.isBlendingEnabled = true
      attachment.rgbBlendOperation = .add
      attachment.sourceRGBBlendFactor = .sourceAlpha
      attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
      
      // water pipeline state
      descriptor.vertexFunction =
        library.makeFunction(name: "vertex_water")
      descriptor.fragmentFunction =
        library.makeFunction(name: "fragment_water")
      descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
      descriptor.vertexDescriptor =
        MTKMetalVertexDescriptorFromModelIO(water.vertexDescriptor)
      try waterPipelineState =
        device.makeRenderPipelineState(descriptor: descriptor)
      
    } catch let error {
      fatalError(error.localizedDescription)
    }
  }
  
  func buildDepthStencilState() {
    let descriptor = MTLDepthStencilDescriptor()
    descriptor.depthCompareFunction = .lessEqual
    descriptor.isDepthWriteEnabled = true
    depthStencilState = Renderer.device.makeDepthStencilState(descriptor: descriptor)
  }
}

extension Renderer: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    camera.aspect = Float(size.width / size.height)
    reflectionRenderPass.updateTextures(size: size)
    refractionRenderPass.updateTextures(size: size)
  }
  
  func draw(in view: MTKView) {
    guard let drawable = view.currentDrawable,
      let descriptor = view.currentRenderPassDescriptor,
      let commandBuffer = commandQueue.makeCommandBuffer()
      else { return }
    
    timer += 0.0001
    uniforms.projectionMatrix = camera.projectionMatrix
    uniforms.cameraPosition = camera.transform.position
    
    // Water render
    var clipPlane = float4(0, 1, 0, 0.1)
    uniforms.clipPlane = clipPlane
    
    let reflectEncoder =
      commandBuffer.makeRenderCommandEncoder(
        descriptor: reflectionRenderPass.descriptor)!
    reflectEncoder.setDepthStencilState(depthStencilState)
    reflectionCamera.transform = camera.transform
    reflectionCamera.transform.position.y = -camera.transform.position.y
    reflectionCamera.transform.rotation.x = -camera.transform.rotation.x
    uniforms.viewMatrix = reflectionCamera.viewMatrix
    renderHouse(renderEncoder: reflectEncoder)
    renderTerrain(renderEncoder: reflectEncoder)
    renderSkybox(renderEncoder: reflectEncoder)
    reflectEncoder.endEncoding()

    clipPlane = float4(0, -1, 0, 0.1)
    uniforms.clipPlane = clipPlane
    uniforms.viewMatrix = camera.viewMatrix
    let refractEncoder =
      commandBuffer.makeRenderCommandEncoder(
        descriptor: refractionRenderPass.descriptor)!
    refractEncoder.setDepthStencilState(depthStencilState)
    renderHouse(renderEncoder: refractEncoder)
    renderTerrain(renderEncoder: refractEncoder)
    renderSkybox(renderEncoder: refractEncoder)
    refractEncoder.endEncoding()
    
    // Main render
    clipPlane = float4(0, -1, 0, 100)
    uniforms.clipPlane = clipPlane
    uniforms.viewMatrix = camera.viewMatrix
    
    let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
    renderEncoder.setDepthStencilState(depthStencilState)
    renderHouse(renderEncoder: renderEncoder)
    renderTerrain(renderEncoder: renderEncoder)
    renderSkybox(renderEncoder: renderEncoder)
    renderWater(renderEncoder: renderEncoder)
    renderEncoder.endEncoding()
    
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
