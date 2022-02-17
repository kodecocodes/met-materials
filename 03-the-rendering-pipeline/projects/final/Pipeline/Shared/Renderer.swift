/// Copyright (c) 2022 Razeware LLC
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

class Renderer: NSObject {
  // swiftlint:disable implicitly_unwrapped_optional
  static var device: MTLDevice!
  static var commandQueue: MTLCommandQueue!
  static var library: MTLLibrary!
  var mesh: MTKMesh!
  var vertexBuffer: MTLBuffer!
  var pipelineState: MTLRenderPipelineState!

  init(metalView: MTKView) {
    guard
      let device = MTLCreateSystemDefaultDevice(),
      let commandQueue = device.makeCommandQueue() else {
        fatalError("GPU not available")
    }
    Renderer.device = device
    Renderer.commandQueue = commandQueue
    metalView.device = device

    // create the mesh
    let allocator = MTKMeshBufferAllocator(device: device)
    let size: Float = 0.8
    let mdlMesh = MDLMesh(
      boxWithExtent: [size, size, size],
      segments: [1, 1, 1],
      inwardNormals: false,
      geometryType: .triangles,
      allocator: allocator)
    do {
      mesh = try MTKMesh(mesh: mdlMesh, device: device)
    } catch let error {
      print(error.localizedDescription)
    }
    vertexBuffer = mesh.vertexBuffers[0].buffer

    // create the shader function library
    let library = device.makeDefaultLibrary()
    Renderer.library = library
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
      MTKMetalVertexDescriptorFromModelIO(mdlMesh.vertexDescriptor)
    do {
      pipelineState =
        try device.makeRenderPipelineState(
          descriptor: pipelineDescriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }

    super.init()
    metalView.clearColor = MTLClearColor(
      red: 1.0,
      green: 1.0,
      blue: 0.8,
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
      let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
      let descriptor = view.currentRenderPassDescriptor,
      let renderEncoder =
        commandBuffer.makeRenderCommandEncoder(
          descriptor: descriptor) else {
        return
    }
    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    for submesh in mesh.submeshes {
      renderEncoder.drawIndexedPrimitives(
        type: .triangle,
        indexCount: submesh.indexCount,
        indexType: submesh.indexType,
        indexBuffer: submesh.indexBuffer.buffer,
        indexBufferOffset: submesh.indexBuffer.offset)
    }

    // 1
    renderEncoder.endEncoding()
    // 2
    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    // 3
    commandBuffer.commit()
  }
}
