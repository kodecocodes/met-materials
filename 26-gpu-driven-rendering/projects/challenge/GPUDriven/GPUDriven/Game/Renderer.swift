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

enum RenderState {
  case shadowPass, mainPass
}

class Renderer: NSObject {
  static var device: MTLDevice!
  static var commandQueue: MTLCommandQueue!
  static var library: MTLLibrary!
  static var viewColorPixelFormat: MTLPixelFormat!

  let options: Options

  var uniforms = Uniforms()
  var params = Params()

  var indirectRenderPass: IndirectRenderPass
  var forwardRenderPass: ForwardRenderPass

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

    indirectRenderPass = IndirectRenderPass()
    forwardRenderPass = ForwardRenderPass()
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
  }

  func initialize(_ scene: GameScene) {
    TextureController.heap = TextureController.buildHeap()
    for model in scene.allModels {
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
    indirectRenderPass.initialize(models: scene.staticModels)
  }
}

extension Renderer {
  func mtkView(
    _ view: MTKView,
    drawableSizeWillChange size: CGSize
  ) {
    indirectRenderPass.resize(view: view, size: size)
    forwardRenderPass.resize(view: view, size: size)
  }

  func updateUniforms(scene: GameScene) {
    uniforms.viewMatrix = scene.camera.viewMatrix
    uniforms.projectionMatrix = scene.camera.projectionMatrix
    params.lightCount = UInt32(scene.lighting.lights.count)
    params.cameraPosition = scene.camera.position
  }

  func draw(scene: GameScene, in view: MTKView) {
    guard
      let commandBuffer = Self.commandQueue.makeCommandBuffer(),
      let descriptor = view.currentRenderPassDescriptor else {
        return
    }

    updateUniforms(scene: scene)

    indirectRenderPass.descriptor = descriptor
    indirectRenderPass.draw(
      commandBuffer: commandBuffer,
      scene: scene,
      uniforms: uniforms,
      params: params)

    forwardRenderPass.descriptor = descriptor
    forwardRenderPass.draw(
      commandBuffer: commandBuffer,
      scene: scene,
      uniforms: uniforms,
      params: params)

    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}

// swiftlint:enable implicitly_unwrapped_optional
