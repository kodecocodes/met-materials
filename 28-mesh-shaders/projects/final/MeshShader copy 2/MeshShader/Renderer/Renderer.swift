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

import MetalKit

class Renderer: NSObject {
  static var device: MTLDevice!
  static var commandQueue: MTLCommandQueue!
  static var library: MTLLibrary!
  static var viewColorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
  static var viewDepthPixelFormat = MTLPixelFormat.depth32Float
  static var scaleFactor: CGFloat = 1

  var uniforms = Uniforms()

  var vertexRenderPass: VertexRenderPass
  var meshRenderPass: MeshRenderPass
  var grassRenderPass: GrassRenderPass
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
    vertexRenderPass = VertexRenderPass()
    grassRenderPass = GrassRenderPass()
    meshRenderPass = MeshRenderPass()

    self.options = options

    super.init()
    metalView.clearColor = MTLClearColor(
      red: 0.7,
      green: 0.9,
      blue: 1.0,
      alpha: 1.0)
    metalView.depthStencilPixelFormat = .depth32Float
    mtkView(
      metalView,
      drawableSizeWillChange: metalView.drawableSize)
  }
}

extension Renderer {
  func mtkView(
    _ view: MTKView,
    drawableSizeWillChange size: CGSize
  ) {
    vertexRenderPass.resize(view: view, size: size)
    grassRenderPass.resize(view: view, size: size)
    meshRenderPass.resize(view: view, size: size)
  }

  func updateUniforms(scene: GameScene) {
    uniforms.viewMatrix = scene.camera.viewMatrix
    uniforms.projectionMatrix = scene.camera.projectionMatrix
  }

  func draw(scene: GameScene, in view: MTKView) {
    guard
      let commandBuffer = Self.commandQueue.makeCommandBuffer(),
      let descriptor = view.currentRenderPassDescriptor else {
        return
    }

    updateUniforms(scene: scene)

    var renderPass: RenderPass
    switch options.renderChoice {
    case .vertexShader:
      renderPass = vertexRenderPass
    case .meshShader:
      renderPass = meshRenderPass
    case .grassShader:
      renderPass = grassRenderPass
    }
    renderPass.descriptor = descriptor
    renderPass.draw(commandBuffer: commandBuffer, scene: scene, uniforms: uniforms)

    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
  }
}

// swiftlint:enable implicitly_unwrapped_optional
