import MetalKit

public class Renderer: NSObject {
  public var isWireframe = false

  let skyboxDimensions: int2 = [256, 256]

  let device: MTLDevice
  let commandQueue: MTLCommandQueue!
  var depthStencilState: MTLDepthStencilState!
  var texture: MTLTexture?

  var camera = ArcballCamera()
  var lastTime: Double = CFAbsoluteTimeGetCurrent()

  var options: Options

  lazy var terrain = {
    return Terrain(device: device)
  }()

  lazy var skybox: MTKMesh = {
    do {
      let allocator = MTKMeshBufferAllocator(device: device)
      let cube = MDLMesh(
        boxWithExtent: [1, 1, 1],
        segments: [1, 1, 1],
        inwardNormals: true,
        geometryType: .triangles,
        allocator: allocator)
      let model = try MTKMesh(
        mesh: cube, device: device)
      return model
    } catch {
      fatalError("failed to create skybox mesh")
    }
  }()
  var skyboxTexture: MTLTexture?
  var skyboxPipelineState: MTLRenderPipelineState!

  public init(metalView: MTKView, options: Options) {
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("GPU not available")
    }
    metalView.device = device
    self.device = device
    commandQueue = device.makeCommandQueue()!
    self.options = options
    super.init()
    metalView.clearColor = MTLClearColor(
      red: 1, green: 1, blue: 0.8, alpha: 1)
    metalView.depthStencilPixelFormat = .depth32Float
    metalView.delegate = self

    buildPipelineState()
    buildDepthStencilState()

    camera.position = [-0.74, 0.5, 2.34]
    camera.rotation = [0.2, 2.84, 0]
    camera.target.y = 1.0

    terrain.rotation.x =  -.pi / 2
    terrain.scale = [50, 50, 50]
    terrain.texture = Renderer.loadTexture(
      imageName: "grass.png",
      device: device)
  }

  func buildPipelineState() {
    do {
      let library = device.makeDefaultLibrary()!
      let fragmentFunction = library.makeFunction(name: "fragment_main")
      let descriptor = MTLRenderPipelineDescriptor()
      descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
      descriptor.depthAttachmentPixelFormat = .depth32Float
      descriptor.fragmentFunction = fragmentFunction

      // terrain pipeline state
      descriptor.vertexFunction = library.makeFunction(name: "vertex_terrain")
      try terrain.pipelineState = device.makeRenderPipelineState(descriptor: descriptor)

      // skybox pipeline state
      descriptor.vertexFunction = library.makeFunction(name: "vertex_skybox")
      descriptor.fragmentFunction = library.makeFunction(name: "fragment_skybox")
      descriptor.vertexDescriptor =
        MTKMetalVertexDescriptorFromModelIO(skybox.vertexDescriptor)
      try skyboxPipelineState =
        device.makeRenderPipelineState(descriptor: descriptor)
    } catch {
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
    } catch {
      fatalError(error.localizedDescription)
    }
    return texture
  }

  func loadGeneratedSkyboxTexture(dimensions: int2) -> MTLTexture? {
    var texture: MTLTexture?
    let skyTexture = MDLSkyCubeTexture(
      name: "sky",
      channelEncoding: .float16,
      textureDimensions: dimensions,
      turbidity: options.turbidity,
      sunElevation: options.sunElevation,
      upperAtmosphereScattering: options.upperAtmosphereScattering,
      groundAlbedo: options.groundAlbedo)
    do {
      let textureLoader = MTKTextureLoader(device: device)
      texture = try textureLoader.newTexture(texture: skyTexture, options: nil)
    } catch {
      print(error.localizedDescription)
    }
    options.shouldGenerateSkybox = false
    return texture
  }
}

extension Renderer: MTKViewDelegate {
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    camera.update(size: size)
  }

  public func draw(in view: MTKView) {
    guard let drawable = view.currentDrawable,
      let descriptor = view.currentRenderPassDescriptor,
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
      else { return }

    let currentTime = CFAbsoluteTimeGetCurrent()
    let deltaTime = (currentTime - lastTime)
    lastTime = currentTime

    camera.update(deltaTime: Float(deltaTime))

    // update skybox
    if options.shouldGenerateSkybox {
      skyboxTexture = loadGeneratedSkyboxTexture(dimensions: [256, 256])
    }

    // render planebuffer
    renderEncoder.setCullMode(.back)
    renderEncoder.setFrontFacing(.clockwise)
    renderEncoder.setRenderPipelineState(terrain.pipelineState)
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setVertexBuffer(terrain.buffer, offset: 0, index: 0)
    renderEncoder.setVertexBuffer(terrain.uvBuffer, offset: 0, index: 3)

    var modelViewProjectionMatrix =
      camera.projectionMatrix * camera.viewMatrix * terrain.modelMatrix
    renderEncoder.setVertexBytes(
      &modelViewProjectionMatrix,
      length: MemoryLayout<float4x4>.stride,
      index: 1)

    var tiling: float2 = [30, 30]
    renderEncoder.setFragmentBytes(
      &tiling,
      length: MemoryLayout<float2>.stride,
      index: 1)

    renderEncoder.setFragmentTexture(terrain.texture, index: 0)
    renderEncoder.drawPrimitives(
      type: .triangle,
      vertexStart: 0,
      vertexCount: terrain.vertices.count / 3)

    // render skybox
    renderEncoder.setCullMode(.front)
    renderEncoder.setFrontFacing(.counterClockwise)

    renderEncoder.setRenderPipelineState(skyboxPipelineState)
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setVertexBuffer(
      skybox.vertexBuffers[0].buffer,
      offset: 0,
      index: 0)

    var matrix = camera.viewMatrix
    matrix.columns.3 = [0, 0, 0, 1]
    var viewProjectionMatrix = camera.projectionMatrix * matrix
    renderEncoder.setVertexBytes(
      &viewProjectionMatrix,
      length: MemoryLayout<float4x4>.stride,
      index: 1)
    renderEncoder.setFragmentTexture(skyboxTexture, index: 0)
    let submesh = skybox.submeshes[0]
    renderEncoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: submesh.indexCount,
      indexType: submesh.indexType,
      indexBuffer: submesh.indexBuffer.buffer,
      indexBufferOffset: 0)
    renderEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}

