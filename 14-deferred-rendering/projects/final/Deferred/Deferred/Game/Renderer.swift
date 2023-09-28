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

class Renderer: NSObject {
  static var device: MTLDevice!
  static var commandQueue: MTLCommandQueue!
  static var library: MTLLibrary!

  var uniforms = Uniforms()
  var params = Params()

  var shadowRenderPass: ShadowRenderPass
  var forwardRenderPass: ForwardRenderPass
  var gBufferRenderPass: GBufferRenderPass
  var lightingRenderPass: LightingRenderPass

  var shadowCamera = OrthographicCamera()

  let options: Options

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

    shadowRenderPass = ShadowRenderPass()
    forwardRenderPass = ForwardRenderPass(view: metalView)
    gBufferRenderPass = GBufferRenderPass(view: metalView)
    lightingRenderPass = LightingRenderPass(view: metalView)

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

    // set the device's scale factor
#if os(macOS)
    params.scaleFactor = Float(NSScreen.main?.backingScaleFactor ?? 1)
#elseif os(iOS)
    params.scaleFactor = Float(UIScreen.main.scale)
#endif
  }
}

extension Renderer {
  func mtkView(
    _ view: MTKView,
    drawableSizeWillChange size: CGSize
  ) {
    shadowRenderPass.resize(view: view, size: size)
    forwardRenderPass.resize(view: view, size: size)
    gBufferRenderPass.resize(view: view, size: size)
    lightingRenderPass.resize(view: view, size: size)
  }

  func updateUniforms(scene: GameScene) {
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
  }

  func draw(scene: GameScene, in view: MTKView) {
    guard
      let commandBuffer = Self.commandQueue.makeCommandBuffer(),
      let descriptor = view.currentRenderPassDescriptor else {
        return
    }

    updateUniforms(scene: scene)

    shadowRenderPass.draw(
      commandBuffer: commandBuffer,
      scene: scene,
      uniforms: uniforms,
      params: params)

    if options.renderChoice == .deferred {
      gBufferRenderPass.shadowTexture = shadowRenderPass.shadowTexture
      gBufferRenderPass.draw(
        commandBuffer: commandBuffer,
        scene: scene,
        uniforms: uniforms,
        params: params)

      lightingRenderPass.albedoTexture = gBufferRenderPass.albedoTexture
      lightingRenderPass.normalTexture = gBufferRenderPass.normalTexture
      lightingRenderPass.positionTexture = gBufferRenderPass.positionTexture
      lightingRenderPass.descriptor = descriptor
      lightingRenderPass.draw(
        commandBuffer: commandBuffer,
        scene: scene,
        uniforms: uniforms,
        params: params)
    } else {
      forwardRenderPass.shadowTexture = shadowRenderPass.shadowTexture
      forwardRenderPass.descriptor = descriptor
      forwardRenderPass.draw(
        commandBuffer: commandBuffer,
        scene: scene,
        uniforms: uniforms,
        params: params)
    }

    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}

// swiftlint:enable implicitly_unwrapped_optional
