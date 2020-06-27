///// Copyright (c) 2019 Razeware LLC
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
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import MetalKit

class Renderer: NSObject {
  
  static var device: MTLDevice!
  static var commandQueue: MTLCommandQueue!
  static var colorPixelFormat: MTLPixelFormat!
  static var library: MTLLibrary?
  var depthStencilState: MTLDepthStencilState
  var renderPipelineState: MTLRenderPipelineState
  var wireframe = true

  // model transform
  var position = float3([0, 0, 0])
  var rotation = float3(Float(-90).degreesToRadians, 0, 0)
  var modelMatrix: float4x4 {
    let translationMatrix = float4x4(translation: position)
    let rotationMatrix = float4x4(rotation: rotation)
    return translationMatrix * rotationMatrix
  }

  init(metalView: MTKView) {
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("GPU not available")
    }
    metalView.depthStencilPixelFormat = .depth32Float
    metalView.device = device
    Renderer.device = device
    Renderer.commandQueue = device.makeCommandQueue()!
    Renderer.colorPixelFormat = metalView.colorPixelFormat
    Renderer.library = device.makeDefaultLibrary()
    
    renderPipelineState = Renderer.buildRenderPipelineState()
    depthStencilState = Renderer.buildDepthStencilState()
    super.init()
    metalView.clearColor = MTLClearColor(red: 1, green: 1,
                                         blue: 1, alpha: 1)
    metalView.delegate = self
  }
  
  static func buildDepthStencilState() -> MTLDepthStencilState {
    let descriptor = MTLDepthStencilDescriptor()
    descriptor.depthCompareFunction = .less
    descriptor.isDepthWriteEnabled = true
    return Renderer.device.makeDepthStencilState(descriptor: descriptor)!
  }
  
  static func buildRenderPipelineState() -> MTLRenderPipelineState {
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    descriptor.depthAttachmentPixelFormat = .depth32Float

    let vertexFunction = Renderer.library?.makeFunction(name: "vertex_main")
    let fragmentFunction = Renderer.library?.makeFunction(name: "fragment_main")
    descriptor.vertexFunction = vertexFunction
    descriptor.fragmentFunction = fragmentFunction
    
    let vertexDescriptor = MTLVertexDescriptor()
    vertexDescriptor.attributes[0].format = .float3
    vertexDescriptor.attributes[0].offset = 0
    vertexDescriptor.attributes[0].bufferIndex = 0
    
    vertexDescriptor.layouts[0].stride = MemoryLayout<float3>.stride
    descriptor.vertexDescriptor = vertexDescriptor
    
    return try! device.makeRenderPipelineState(descriptor: descriptor)
  }
}

extension Renderer: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
  }
  
  func draw(in view: MTKView) {
    guard let descriptor = view.currentRenderPassDescriptor,
      let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
      let drawable =  view.currentDrawable
      else {
        return
    }
    // uniforms
    let projectionMatrix = float4x4(projectionFov: 1.2, near: 0.01, far: 100,
                                    aspect: Float(view.bounds.width/view.bounds.height))
    let viewMatrix = float4x4(translation: [0, 0, -1.8])
    var mvp = projectionMatrix * viewMatrix.inverse * modelMatrix

    
    // tessellation pass
    
    
    // render
    let renderEncoder =
      commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setVertexBytes(&mvp, length: MemoryLayout<float4x4>.stride, index: 1)
    renderEncoder.setRenderPipelineState(renderPipelineState)
    renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    let fillmode: MTLTriangleFillMode = wireframe ? .lines : .fill
    renderEncoder.setTriangleFillMode(fillmode)

    // draw
    renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)

    renderEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}


