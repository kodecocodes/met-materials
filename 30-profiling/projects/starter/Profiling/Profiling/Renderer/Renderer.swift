///// Copyright (c) 2025 Kodeco Inc.
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

// swiftlint:disable implicitly_unwrapped_optional
// swiftlint:disable force_try
// swiftlint:disable force_unwrapping
// swiftlint:disable function_body_length

import MetalKit

// Properties that will improve efficiency when changed
let maxFramesInFlight = 1
let doUpscaling = false
let kUpscaleAmount: CGFloat = 2
let cullFaces = false

let wireframe = false

enum RenderState {
  case shadowPass, mainPass
}

class Renderer: NSObject {
  static var device: MTLDevice!
  static var commandQueue: MTLCommandQueue!
  static var library: MTLLibrary!
  static var viewColorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
  static var viewDepthPixelFormat = MTLPixelFormat.depth32Float
  static var scaleFactor: CGFloat = 1
  static var currentFrameIndex = 0  // marks the current frame

  var uniforms: [MTLBuffer]
  var params = Params()

  var shadowRenderPass: ShadowRenderPass
  var forwardRenderPass: ForwardRenderPass
  var natureRenderPass: NatureRenderPass
  var skyboxRenderPass: SkyboxRenderPass
  var waterRenderPass: WaterRenderPass
  var particlesRenderPass: ParticlesRenderPass
  var upscalePass: UpscalePass?
  var brighten: Brighten
  var bloom: Bloom

  var shadowCamera = OrthographicCamera()
  var transparentRenderPass: TransparentRenderPass
  let options: Options

  let residencySet: MTLResidencySet

  init(metalView: MTKView, options: Options) {
    guard
      let device = MTLCreateSystemDefaultDevice(),
      let commandQueue = device.makeCommandQueue() else {
        fatalError("GPU not available")
    }
    Self.device = device
    Self.commandQueue = commandQueue
    metalView.device = device
    metalView.colorPixelFormat = Self.viewColorPixelFormat
  #if os(macOS)
    Self.scaleFactor = NSScreen.main?.backingScaleFactor ?? 1
  #elseif os(iOS)
    Self.scaleFactor = metalView.traitCollection.displayScale
  #endif

    // create the shader function library
    let library = device.makeDefaultLibrary()
    Self.library = library

    // Initialize Render Passes
    shadowRenderPass = ShadowRenderPass()
    forwardRenderPass = ForwardRenderPass(view: metalView)
    natureRenderPass = NatureRenderPass()
    skyboxRenderPass = SkyboxRenderPass()
    transparentRenderPass = TransparentRenderPass(view: metalView)
    waterRenderPass = WaterRenderPass(view: metalView)
    particlesRenderPass = ParticlesRenderPass(view: metalView)

    // MetalFX Upscaling
    if doUpscaling {
      upscalePass = UpscalePass(view: metalView)
    }

    // post processing
    brighten = Brighten()
    bloom = Bloom()

    self.options = options

    let setDescriptor = MTLResidencySetDescriptor()
    setDescriptor.label = "Residency Set"
    setDescriptor.initialCapacity = 1
    residencySet = try! device.makeResidencySet(
      descriptor: setDescriptor)

    uniforms = (0..<maxFramesInFlight).map { index in
      let buffer = Renderer.device.makeBuffer(length: MemoryLayout<Uniforms>.stride)!
      buffer.label = "Uniforms \(index)"
      return buffer
    }

    super.init()
    metalView.clearColor = MTLClearColor(
      red: 0.93,
      green: 0.97,
      blue: 1.0,
      alpha: 1.0)

    // remove this
    metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
    metalView.depthStencilPixelFormat = .depth32Float
    metalView.framebufferOnly = false

    mtkView(
      metalView,
      drawableSizeWillChange: metalView.drawableSize)
  }

  func initialize(_ scene: GameScene) {
    TextureController.heap = TextureController.buildHeap()
    if let heap = TextureController.heap {
      residencySet.addAllocation(heap)
      residencySet.commit()
      Renderer.commandQueue.addResidencySet(residencySet)
    }

    for model in scene.models {
      model.meshes = model.meshes.map { mesh in
        var mesh = mesh
        mesh.submeshes = mesh.submeshes.map { submesh in
          var submesh = submesh
          submesh.initializeMaterials()
          return submesh
        }
        return mesh
      }
    }
  }
}

extension Renderer {
  func mtkView(
    _ view: MTKView,
    drawableSizeWillChange size: CGSize
  ) {
    if size == .zero { return }
    shadowRenderPass.resize(view: view, size: size)
    forwardRenderPass.resize(view: view, size: size)
    natureRenderPass.resize(view: view, size: size)
    skyboxRenderPass.resize(view: view, size: size)
    waterRenderPass.resize(view: view, size: size)
    particlesRenderPass.resize(view: view, size: size)
    brighten.resize(view: view, size: size)
    bloom.resize(view: view, size: size)
    upscalePass?.resize(view: view, size: size)
    params.width = UInt32(size.width)
    params.height = UInt32(size.height)
    params.scaleFactor = Float(Self.scaleFactor)
  }

  func updateUniforms(scene: GameScene) {
    params.alphaBlending = options.alphaBlending

    let pointer = uniforms[Self.currentFrameIndex]
      .contents().bindMemory(to: Uniforms.self, capacity: 1)
    var uniforms = pointer.pointee
    uniforms.viewMatrix = scene.camera.viewMatrix
    uniforms.projectionMatrix = scene.camera.projectionMatrix

    params.lightCount = UInt32(scene.lighting.lights.count)
    params.cameraPosition = scene.camera.position

    let sun = scene.lighting.lights[0]
    shadowCamera = OrthographicCamera.createShadowCamera(
      using: scene.camera,
      lightPosition: sun.position)
    uniforms.shadowProjectionMatrix = shadowCamera.projectionMatrix
    uniforms.shadowViewMatrix = float4x4(
      eye: shadowCamera.position,
      target: shadowCamera.center,
      up: [0, 1, 0])
    pointer.pointee = uniforms
  }

  func draw(scene: GameScene, in view: MTKView) {
    guard
      let commandBuffer = Self.commandQueue.makeCommandBuffer(),
      let viewDescriptor = view.currentRenderPassDescriptor else {
        return
    }

    // Update scene
    updateUniforms(scene: scene)
    let uniforms = uniforms[Self.currentFrameIndex]

    upscalePass?.update()

    let descriptor = upscalePass?.descriptor ?? viewDescriptor
    shadowRenderPass.draw(
      commandBuffer: commandBuffer,
      scene: scene,
      uniforms: uniforms,
      params: params)

    forwardRenderPass.shadowTexture = shadowRenderPass.shadowTexture
    forwardRenderPass.descriptor = descriptor
    forwardRenderPass.draw(
      commandBuffer: commandBuffer,
      scene: scene,
      uniforms: uniforms,
      params: params)

    bloom.postProcess(
      view: view,
      commandBuffer: commandBuffer,
      inputTexture: descriptor.colorAttachments[0].texture)

    waterRenderPass.skyTexture = scene.skybox?.skyTexture
    waterRenderPass.descriptor = descriptor
    waterRenderPass.draw(
      commandBuffer: commandBuffer,
      scene: scene,
      uniforms: uniforms,
      params: params)

    natureRenderPass.descriptor = descriptor
    natureRenderPass.draw(
      commandBuffer: commandBuffer,
      scene: scene,
      uniforms: uniforms,
      params: params)


    skyboxRenderPass.descriptor = descriptor
    skyboxRenderPass.draw(
      commandBuffer: commandBuffer,
      scene: scene,
      uniforms: uniforms,
      params: params)

    transparentRenderPass.shadowTexture = shadowRenderPass.shadowTexture
    transparentRenderPass.descriptor = descriptor
    transparentRenderPass.draw(
      commandBuffer: commandBuffer,
      scene: scene,
      uniforms: uniforms,
      params: params)

    particlesRenderPass.descriptor = descriptor
    particlesRenderPass.draw(
      commandBuffer: commandBuffer,
      scene: scene,
      uniforms: uniforms,
      params: params)

    upscalePass?.upscale(commandBuffer: commandBuffer)

    brighten.postProcess(
      view: view,
      commandBuffer: commandBuffer,
      inputTexture: descriptor.colorAttachments[0].texture)

    guard let drawable = view.currentDrawable else {
      return
    }
    if let upscaledTexture = upscalePass?.currentFrameUpscaledColor {
      if let blitEncoder = commandBuffer.makeBlitCommandEncoder() {
        blitEncoder.copy(from: upscaledTexture, to: drawable.texture)
        blitEncoder.endEncoding()
      }
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}

// swiftlint:enable implicitly_unwrapped_optional
// swiftlint:enable force_try
// swiftlint:enable force_unwrapping
// swiftlint:enable function_body_length
