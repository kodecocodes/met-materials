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

import MetalKit

enum PipelineStates {
  static func createPSO(descriptor: MTLRenderPipelineDescriptor)
  -> MTLRenderPipelineState {
    let pipelineState: MTLRenderPipelineState
    do {
      pipelineState =
      try Renderer.device.makeRenderPipelineState(
        descriptor: descriptor)
    } catch {
      fatalError(error.localizedDescription)
    }
    return pipelineState
  }
  
  static func createComputePSO(function: String)
  -> MTLComputePipelineState {
    guard let kernel = Renderer.library.makeFunction(name: function)
    else { fatalError("Unable to create \(function) PSO") }
    let pipelineState: MTLComputePipelineState
    do {
      pipelineState =
      try Renderer.device.makeComputePipelineState(function: kernel)
    } catch {
      fatalError(error.localizedDescription)
    }
    return pipelineState
  }
  
  static func createForwardPSO(indirect: Bool = false)
  -> MTLRenderPipelineState {
    let vertexFunction = Renderer.library.makeFunction(name: "vertex_main")
    let fragmentFunction = Renderer.library.makeFunction(name: "fragment_main")
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat
    = Renderer.viewColorPixelFormat
    let attachment = pipelineDescriptor.colorAttachments[0]
    attachment?.isBlendingEnabled = true
    attachment?.rgbBlendOperation = .add
    attachment?.sourceRGBBlendFactor = .sourceAlpha
    attachment?.destinationRGBBlendFactor = .oneMinusSourceAlpha
    
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.vertexDescriptor =
    MTLVertexDescriptor.defaultLayout
    pipelineDescriptor.supportIndirectCommandBuffers = indirect
    return createPSO(descriptor: pipelineDescriptor)
  }
  
  static func createGrassPSO()
  -> MTLRenderPipelineState {
    let vertexFunction = Renderer.library.makeFunction(name: "vertex_grass")
    let fragmentFunction = Renderer.library.makeFunction(name: "fragment_grass")
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat
    = Renderer.viewColorPixelFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.vertexDescriptor =
    MTLVertexDescriptor.grassLayout
    return createPSO(descriptor: pipelineDescriptor)
  }
  
  static func grassPointsPSO()
  -> MTLRenderPipelineState {
    let vertexFunction = Renderer.library.makeFunction(name: "vertex_point")
    let fragmentFunction = Renderer.library.makeFunction(name: "fragment_point")
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat
      = Renderer.viewColorPixelFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    return createPSO(descriptor: pipelineDescriptor)
  }

  static func grassMeshPSO() -> MTLRenderPipelineState {
    let library = Renderer.library
    let descriptor = MTLMeshRenderPipelineDescriptor()

    // Set the shader functions
    descriptor.objectFunction = library?.makeFunction(name: "grassObjectShader")
    descriptor.meshFunction = library?.makeFunction(name: "grassMeshShader")
    descriptor.fragmentFunction = library?.makeFunction(name: "grassFragmentShader") // You'll need this

    // Set render target format
    descriptor.colorAttachments[0].pixelFormat = Renderer.viewColorPixelFormat
    descriptor.depthAttachmentPixelFormat = Renderer.viewDepthPixelFormat

    // Set payload size (16KB max)
    descriptor.payloadMemoryLength = MemoryLayout<GrassPayload>.stride

    // Set thread group sizes
    descriptor.maxTotalThreadsPerObjectThreadgroup = 1
    descriptor.maxTotalThreadsPerMeshThreadgroup = Int(GrassThreadsPerMeshThreadgroup)
    do {
      let (pipelineState, _) = try Renderer.device.makeRenderPipelineState(
        descriptor: descriptor,
        options: MTLPipelineOption())
      return pipelineState
    } catch {
      fatalError("Unable to create grass mesh pipeline state: \(error)")
    }
  }
}
