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

// swiftlint:disable implicitly_unwrapped_optional

let maxFramesInFlight = 1

enum RenderState {
  case shadowPass, mainPass
}

class Renderer: NSObject {
  static var currentFrameIndex = 0  // marks the current frame

  static var device: MTLDevice!
  static var commandQueue: MTLCommandQueue!
  static var library: MTLLibrary!
  static var viewColorPixelFormat: MTLPixelFormat!
  static var cullFaces = false

  let options: Options

  var params = Params()
  var uniformsBuffers: [MTLBuffer]

  var forwardRenderPass: ForwardRenderPass
  var shadowRenderPass: ShadowRenderPass
  var skyboxRenderPass: SkyboxRenderPass
  var natureRenderPass: NatureRenderPass
  var bloom = Bloom()
  var shadowCamera = OrthographicCamera()

  init(metalView: MTKView, options: Options) {
    guard
      let device = MTLCreateSystemDefaultDevice(),
      let commandQueue = device.makeCommandQueue() else {
        fatalError("GPU not available")
    }
    Self.device = device
    Self.commandQueue = commandQueue
    metalView.device = device

    // create the shader function library
    let library = device.makeDefaultLibrary()
    Self.library = library
    Self.viewColorPixelFormat = metalView.colorPixelFormat

    forwardRenderPass = ForwardRenderPass()
    shadowRenderPass = ShadowRenderPass()
    natureRenderPass = NatureRenderPass()
    skyboxRenderPass = SkyboxRenderPass()

    uniformsBuffers = (0..<maxFramesInFlight).map { _ in
      Renderer.device.makeBuffer(length: MemoryLayout<Uniforms>.stride)!
    }
    self.options = options
    super.init()
    metalView.clearColor = MTLClearColor(
      red: 0.93,
      green: 0.97,
      blue: 1.0,
      alpha: 1.0)
    metalView.depthStencilPixelFormat = .depth32Float
    mtkView(
      metalView,
      drawableSizeWillChange: metalView.drawableSize)
    metalView.framebufferOnly = false

    // set the device's scale factor
#if os(macOS)
    params.scaleFactor = Float(NSScreen.main?.backingScaleFactor ?? 1)
#elseif os(iOS)
    params.scaleFactor = Float(UIScreen.main.scale)
#endif
  }

  func initialize(_ scene: GameScene) {
    TextureController.heap = TextureController.buildHeap()
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

  static func buildDepthStencilState() -> MTLDepthStencilState? {
    let descriptor = MTLDepthStencilDescriptor()
    descriptor.depthCompareFunction = .less
    descriptor.isDepthWriteEnabled = true
    return Renderer.device.makeDepthStencilState(
      descriptor: descriptor)
  }
}

extension Renderer {
  func mtkView(
    _ view: MTKView,
    drawableSizeWillChange size: CGSize
  ) {
    params.width = UInt32(size.width)
    params.height = UInt32(size.height)
    forwardRenderPass.resize(view: view, size: size)
    shadowRenderPass.resize(view: view, size: size)
    skyboxRenderPass.resize(view: view, size: size)
    natureRenderPass.resize(view: view, size: size)
    bloom.resize(view: view, size: size)
  }

  func updateUniforms(scene: GameScene) {
    params.alphaBlending = options.alphaBlending

    let pointer = uniformsBuffers[Self.currentFrameIndex]
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
      center: shadowCamera.center,
      up: [0, 1, 0])
    pointer.pointee = uniforms
  }

  func draw(scene: GameScene, in view: MTKView) {
    guard
      let commandBuffer = Self.commandQueue.makeCommandBuffer(),
      let descriptor = view.currentRenderPassDescriptor else {
        return
    }

    updateUniforms(scene: scene)
    let uniformsBuffer = uniformsBuffers[Self.currentFrameIndex]

    shadowRenderPass.draw(
      commandBuffer: commandBuffer,
      scene: scene,
      uniformsBuffer: uniformsBuffer,
      params: params)

    forwardRenderPass.shadowTexture = shadowRenderPass.shadowTexture

    forwardRenderPass.descriptor = descriptor
    forwardRenderPass.draw(
      commandBuffer: commandBuffer,
      scene: scene,
      uniformsBuffer: uniformsBuffer,
      params: params)

    natureRenderPass.descriptor = descriptor
    natureRenderPass.draw(
      commandBuffer: commandBuffer,
      scene: scene,
      uniformsBuffer: uniformsBuffer,
      params: params)

    // Post processing without processing the skybox
     bloom.postProcess(view: view, commandBuffer: commandBuffer)

    skyboxRenderPass.descriptor = descriptor
    skyboxRenderPass.draw(
      commandBuffer: commandBuffer,
      scene: scene,
      uniformsBuffer: uniformsBuffer,
      params: params)

    guard let drawable = view.currentDrawable else {
      return
    }

    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
// swiftlint:enable implicitly_unwrapped_optional
