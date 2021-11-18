import MetalKit

public class Renderer: NSObject {
  public var isWireframe = false
  
  let skyboxDimensions: int2 = [256, 256]
  
  let device: MTLDevice
  let commandQueue: MTLCommandQueue!
  var depthStencilState: MTLDepthStencilState!
  var texture: MTLTexture?
  
  let camera = Camera()
  
  lazy var terrain = {
    return Terrain(device: device)
  }()
  
  lazy var skybox: MTKMesh = {
    do {
      let allocator = MTKMeshBufferAllocator(device: device)
      let cube = MDLMesh(boxWithExtent: [1,1,1], segments: [1, 1, 1],
                            inwardNormals: true, geometryType: .triangles,
                            allocator: allocator)
      let model = try MTKMesh(mesh: cube,
                              device: device)
      return model
    } catch {
      fatalError("failed to create skybox mesh")
    }
  }()
  var skyboxTexture: MTLTexture?
  var skyboxPipelineState: MTLRenderPipelineState!
  
  public struct SkyboxSettings {
    public var turbidity: Float = 0.28
    public var sunElevation: Float = 0.6
    public var upperAtmosphereScattering: Float = 0.1
    public var groundAlbedo: Float = 4
  }
  public var skyboxSettings = SkyboxSettings() {
    didSet {
      skyboxTexture = loadGeneratedSkyboxTexture(dimensions: skyboxDimensions)
    }
  }
  
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
    
    skyboxTexture = loadGeneratedSkyboxTexture(dimensions: [256, 256])
    
    camera.transform.position = [0, 0.5, 3]
    terrain.rotation.x =  -.pi / 2
    terrain.scale = [50, 50, 50]
    terrain.texture = Renderer.loadTexture(imageName: "grass.png", device: device)
  }
  
  func buildPipelineState() {
    do {
      guard let path = Bundle.main.path(forResource: "Shaders", ofType: "metal") else { return }
      let source = try String(contentsOfFile: path, encoding: .utf8)
      let library = try device.makeLibrary(source: source, options: nil)
      let fragmentFunction = library.makeFunction(name: "fragment_main")
      let descriptor = MTLRenderPipelineDescriptor()
      descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
      descriptor.depthAttachmentPixelFormat = .depth32Float
      descriptor.fragmentFunction = fragmentFunction
      
      // terrain pipeline state
      descriptor.vertexFunction = library.makeFunction(name: "vertex_terrain")
      try terrain.pipelineState = device.makeRenderPipelineState(descriptor: descriptor)
      
      // skybox pipeline state
      guard let skyboxPath = Bundle.main.path(forResource: "Skybox", ofType: "metal") else { return }
      let skyboxSource = try String(contentsOfFile: skyboxPath, encoding: .utf8)
      let skyboxLibrary = try device.makeLibrary(source: skyboxSource, options: nil)

      descriptor.vertexFunction = skyboxLibrary.makeFunction(name: "vertex_skybox")
      descriptor.fragmentFunction = skyboxLibrary.makeFunction(name: "fragment_skybox")
      descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(skybox.vertexDescriptor)
      try skyboxPipelineState = device.makeRenderPipelineState(descriptor: descriptor)
      
    } catch let error {
      fatalError(error.localizedDescription)
    }
  }
  
  func buildDepthStencilState() {
    let descriptor = MTLDepthStencilDescriptor()
    descriptor.depthCompareFunction = .lessEqual
    descriptor.isDepthWriteEnabled = true
    depthStencilState = device.makeDepthStencilState(descriptor: descriptor)
  }

  static func loadTexture(imageName: String, device: MTLDevice) -> MTLTexture {
    let textureLoader = MTKTextureLoader(device: device)
    let textureLoaderOptions: [MTKTextureLoader.Option: Any] =
      [.origin: MTKTextureLoader.Origin.bottomLeft,
       .SRGB: false,
       .generateMipmaps: NSNumber(booleanLiteral: true)]
    let fileExtension =
      URL(fileURLWithPath: imageName).pathExtension.isEmpty ?
        "png" : nil
    guard let url = Bundle.main.url(forResource: imageName,
                                    withExtension: fileExtension)
      else {
        fatalError("No texture found")
    }
    let texture: MTLTexture
    do {
    texture = try textureLoader.newTexture(URL: url,
                          options: textureLoaderOptions)
    } catch let error {
      fatalError(error.localizedDescription)
    }
    return texture
  }
  
  func loadGeneratedSkyboxTexture(dimensions: int2) -> MTLTexture? {
    var texture: MTLTexture?
    let skyTexture = MDLSkyCubeTexture(name: "sky",
            channelEncoding: .uInt8,
            textureDimensions: dimensions,
            turbidity: skyboxSettings.turbidity,
            sunElevation: skyboxSettings.sunElevation,
            upperAtmosphereScattering: skyboxSettings.upperAtmosphereScattering,
            groundAlbedo: skyboxSettings.groundAlbedo)
    do {
      let textureLoader = MTKTextureLoader(device: device)
      texture = try textureLoader.newTexture(texture: skyTexture, options: nil)
    } catch let error {
      print(error.localizedDescription)
    }
    return texture
  }
  
  public func zoomUsing(delta: CGFloat) {
    let sensitivity = Float(0.1)
    let rotation = camera.transform.rotation
    let dx = Float(delta) * sensitivity * sin(rotation.y)
    let dz = Float(delta) * sensitivity * cos(rotation.y)
    camera.transform.position.x += dx
    camera.transform.position.z -= dz
  }
  
  public func rotateUsing(translation: NSPoint) {
    let sensitivity: Float = 0.01
    camera.transform.rotation.x += Float(translation.y) * sensitivity
    camera.transform.rotation.y -= Float(translation.x) * sensitivity
  }
}

extension Renderer: MTKViewDelegate {
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    camera.aspect = Float(size.width/size.height)
  }
  
  public func draw(in view: MTKView) {
    guard let drawable = view.currentDrawable,
      let descriptor = view.currentRenderPassDescriptor,
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
      else { return }
    
    // render planebuffer
    renderEncoder.setCullMode(.none)
    renderEncoder.setFrontFacing(.counterClockwise)
    renderEncoder.setRenderPipelineState(terrain.pipelineState)
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setVertexBuffer(terrain.buffer, offset: 0, index: 0)
    renderEncoder.setVertexBuffer(terrain.uvBuffer, offset: 0, index: 3)
    
    var modelViewProjectionMatrix = camera.projectionMatrix * camera.viewMatrix * terrain.modelMatrix
    renderEncoder.setVertexBytes(&modelViewProjectionMatrix, length: MemoryLayout<float4x4>.stride, index: 1)
    
    var tiling: float2 = [30, 30]
    renderEncoder.setFragmentBytes(&tiling, length: MemoryLayout<float2>.stride, index: 1)
    
    renderEncoder.setFragmentTexture(terrain.texture, index: 0)
    renderEncoder.drawPrimitives(type: .triangle,
                                 vertexStart: 0,
                                 vertexCount: terrain.vertices.count/3)
    
    // render skybox
    renderEncoder.setCullMode(.back)
    renderEncoder.setFrontFacing(.counterClockwise)
    
    renderEncoder.setRenderPipelineState(skyboxPipelineState)
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setVertexBuffer(skybox.vertexBuffers[0].buffer, offset: 0, index: 0)
    
    var matrix = camera.viewMatrix
    matrix.columns.3 = [0, 0, 0, 1]
    var viewProjectionMatrix = camera.projectionMatrix * matrix
    renderEncoder.setVertexBytes(&viewProjectionMatrix, length: MemoryLayout<float4x4>.stride, index: 1)
    renderEncoder.setFragmentTexture(skyboxTexture, index: 0)
    let submesh = skybox.submeshes[0]
    renderEncoder.drawIndexedPrimitives(type: .triangle,
                                        indexCount: submesh.indexCount,
                                        indexType: submesh.indexType,
                                        indexBuffer: submesh.indexBuffer.buffer,
                                        indexBufferOffset: 0)
    renderEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}

