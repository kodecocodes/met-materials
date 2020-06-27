/**
 * Copyright (c) 2019 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import MetalKit

public typealias float2 = SIMD2<Float>
public typealias float3 = SIMD3<Float>
public typealias float4 = SIMD4<Float>

class Renderer: NSObject, MTKViewDelegate {
    
  static var device: MTLDevice!
  let commandQueue: MTLCommandQueue
  var particlesPipelineState: MTLComputePipelineState!
  var renderPipelineState: MTLRenderPipelineState!
  
  var emitters: [Emitter] = []
  
  init?(metalView: MTKView) {
    guard let device = MTLCreateSystemDefaultDevice(),
      let commandQueue = device.makeCommandQueue() else { return nil }
    Renderer.device = device
    self.commandQueue = commandQueue
    super.init()
    metalView.delegate = self
    metalView.framebufferOnly = false
    metalView.clearColor = MTLClearColor(red: 0.2, green: 0.2,
                                         blue: 0.2, alpha: 1)
    buildPipelineStates()
  }
  
  private func buildPipelineStates() {
    do {
      guard let library = Renderer.device.makeDefaultLibrary(),
        let function = library.makeFunction(name: "compute") else { return }
      
      // particle update pipeline state
      particlesPipelineState = try Renderer.device.makeComputePipelineState(function: function)
      
      // render pipeline state
      let vertexFunction = library.makeFunction(name: "vertex_particle")
      let fragmentFunction = library.makeFunction(name: "fragment_particle")
      let descriptor = MTLRenderPipelineDescriptor()
      descriptor.vertexFunction = vertexFunction
      descriptor.fragmentFunction = fragmentFunction
      descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
      renderPipelineState = try
        Renderer.device.makeRenderPipelineState(descriptor: descriptor)
      renderPipelineState = try Renderer.device.makeRenderPipelineState(descriptor: descriptor)
    } catch let error {
      print(error.localizedDescription)
    }
  }
  
  public func draw(in view: MTKView) {
    guard let commandBuffer = commandQueue.makeCommandBuffer(),
          let descriptor = view.currentRenderPassDescriptor,
          let drawable = view.currentDrawable else { return }
    
    // first command encoder
    // update the particle emitters

    
    // second command encoder
    // render the particle emitters
    
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
  
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
