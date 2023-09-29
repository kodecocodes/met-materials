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
  var options: Options

  let depthStencilState: MTLDepthStencilState?
  var pipelineState: MTLRenderPipelineState

  var timer: Float = 0
  var uniforms = Uniforms()
  var params = Params()

  let quad = Quad()
  var camera = ArcballCamera(distance: 2)

  // model transform
  var modelMatrix: float4x4 {
    let rotation = float3(Float(-90).degreesToRadians, 0, 0)
    return float4x4(rotation: rotation)
  }

  init(metalView: MTKView, options: Options) {
    guard
      let device = MTLCreateSystemDefaultDevice(),
      let commandQueue = device.makeCommandQueue() else {
        fatalError("GPU not available")
    }
    Renderer.device = device
    Renderer.commandQueue = commandQueue
    Renderer.library = device.makeDefaultLibrary()
    metalView.device = device

    pipelineState = PipelineStates.createRenderPSO(
      colorPixelFormat: metalView.colorPixelFormat)
    depthStencilState = Renderer.buildDepthStencilState()

    self.options = options
    super.init()
    metalView.clearColor = MTLClearColor(
      red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    metalView.depthStencilPixelFormat = .depth32Float
    metalView.delegate = self
    mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
  }

  static func buildDepthStencilState() -> MTLDepthStencilState? {
    let descriptor = MTLDepthStencilDescriptor()
    descriptor.depthCompareFunction = .less
    descriptor.isDepthWriteEnabled = true
    return Renderer.device.makeDepthStencilState(
      descriptor: descriptor)
  }
}

extension Renderer: MTKViewDelegate {
  func mtkView(
    _ view: MTKView,
    drawableSizeWillChange size: CGSize
  ) {
    camera.update(size: size)
    params.width = UInt32(size.width)
    params.height = UInt32(size.height)
  }

  func updateUniforms() {
    camera.update(deltaTime: 0.016)
    uniforms.projectionMatrix = camera.projectionMatrix
    uniforms.viewMatrix = camera.viewMatrix
    uniforms.modelMatrix = modelMatrix
    uniforms.mvp = uniforms.projectionMatrix * uniforms.viewMatrix
      * uniforms.modelMatrix
  }

  func tessellation(commandBuffer: MTLCommandBuffer) {
  }

  func render(commandBuffer: MTLCommandBuffer, view: MTKView) {
    guard let descriptor = view.currentRenderPassDescriptor,
      let renderEncoder =
        commandBuffer.makeRenderCommandEncoder(
          descriptor: descriptor) else { return }
    renderEncoder.setDepthStencilState(depthStencilState)

    renderEncoder.setFragmentBytes(
      &params,
      length: MemoryLayout<Uniforms>.stride,
      index: BufferIndexParams.index)
    renderEncoder.setRenderPipelineState(pipelineState)

    renderEncoder.setVertexBytes(
      &uniforms,
      length: MemoryLayout<Uniforms>.stride,
      index: BufferIndexUniforms.index)

    // draw
    renderEncoder.setVertexBuffer(
      quad.vertexBuffer,
      offset: 0,
      index: 0)
    let fillmode: MTLTriangleFillMode = options.isWireframe ? .lines : .fill
    renderEncoder.setTriangleFillMode(fillmode)

    renderEncoder.drawPrimitives(
      type: .triangle,
      vertexStart: 0,
      vertexCount: quad.vertices.count)

    renderEncoder.endEncoding()
  }

  func draw(in view: MTKView) {
    guard
      let commandBuffer = Renderer.commandQueue.makeCommandBuffer() else {
        return
    }
    updateUniforms()

    tessellation(commandBuffer: commandBuffer)

    render(commandBuffer: commandBuffer, view: view)

    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}

// swiftlint:enable implicitly_unwrapped_optional
