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
// swiftlint:disable function_body_length
// swiftlint:disable comma

class Renderer: NSObject {
  static var device: MTLDevice!
  static var commandQueue: MTLCommandQueue!
  static var library: MTLLibrary!
  var pipelineState: MTLRenderPipelineState!

  lazy var triangle: Triangle = {
    Triangle(device: Self.device)
  }()

  var timer: Float = 0

  init(metalView: MTKView) {
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
    let vertexFunction = library?.makeFunction(name: "vertex_main")
    let fragmentFunction =
      library?.makeFunction(name: "fragment_main")

    // create the pipeline state object
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat =
      metalView.colorPixelFormat
    pipelineDescriptor.vertexDescriptor =
      MTLVertexDescriptor.defaultLayout
    do {
      pipelineState =
        try device.makeRenderPipelineState(
          descriptor: pipelineDescriptor)
    } catch {
      fatalError(error.localizedDescription)
    }
    super.init()
    metalView.clearColor = MTLClearColor(
      red: 1.0,
      green: 1.0,
      blue: 0.9,
      alpha: 1.0)
    metalView.delegate = self
  }
}

extension Renderer: MTKViewDelegate {
  func mtkView(
    _ view: MTKView,
    drawableSizeWillChange size: CGSize
  ) {
  }

  func draw(in view: MTKView) {
    guard
      let commandBuffer = Self.commandQueue.makeCommandBuffer(),
      let descriptor = view.currentRenderPassDescriptor,
      let renderEncoder =
        commandBuffer.makeRenderCommandEncoder(
          descriptor: descriptor) else {
        return
    }

    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.setVertexBuffer(
      triangle.vertexBuffer,
      offset: 0,
      index: 0)

    // draw the untransformed triangle in light gray
    var color: simd_float4 = [0.8, 0.8, 0.8, 1]
    renderEncoder.setFragmentBytes(
      &color,
      length: MemoryLayout<SIMD4<Float>>.stride,
      index: 0)
    var translation = matrix_float4x4()
    translation.columns.0 = [1, 0, 0, 0]
    translation.columns.1 = [0, 1, 0, 0]
    translation.columns.2 = [0, 0, 1, 0]
    translation.columns.3 = [0, 0, 0, 1]
    var matrix = translation
    renderEncoder.setVertexBytes(
      &matrix,
      length: MemoryLayout<matrix_float4x4>.stride,
      index: 11)
    renderEncoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: triangle.indices.count,
      indexType: .uint16,
      indexBuffer: triangle.indexBuffer,
      indexBufferOffset: 0)

    // draw the new triangle in red
    color = [1, 0, 0, 1]
    renderEncoder.setFragmentBytes(
      &color,
      length: MemoryLayout<SIMD4<Float>>.stride,
      index: 0)
    let position = simd_float3(0.3, -0.4, 0)
    translation.columns.3.x = position.x
    translation.columns.3.y = position.y
    translation.columns.3.z = position.z

    let scaleX: Float = 1.2
    let scaleY: Float = 0.5
    let scaleMatrix = float4x4(
      [scaleX, 0,   0,   0],
      [0, scaleY,   0,   0],
      [0,      0,   1,   0],
      [0,      0,   0,   1])

    let angle = Float.pi / 2.0
    let rotationMatrix = float4x4(
      [cos(angle), -sin(angle), 0,    0],
      [sin(angle),  cos(angle), 0,    0],
      [0,           0,          1,    0],
      [0,           0,          0,    1])

    translation.columns.3.x = triangle.vertices[2].x
    translation.columns.3.y = triangle.vertices[2].y
    translation.columns.3.z = triangle.vertices[2].z

    matrix = translation * rotationMatrix * translation.inverse

    renderEncoder.setVertexBytes(
      &matrix,
      length: MemoryLayout<matrix_float4x4>.stride,
      index: 11)
    renderEncoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: triangle.indices.count,
      indexType: .uint16,
      indexBuffer: triangle.indexBuffer,
      indexBufferOffset: 0)

    renderEncoder.endEncoding()
    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}

// swiftlint:enable implicitly_unwrapped_optional
// swiftlint:enable function_body_length
// swiftlint:enable comma
