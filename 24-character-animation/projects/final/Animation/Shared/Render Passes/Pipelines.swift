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

enum PipelineStates {
  static func createPSO(descriptor: MTLRenderPipelineDescriptor)
    -> MTLRenderPipelineState {
    let pipelineState: MTLRenderPipelineState
    do {
      pipelineState =
      try Renderer.device.makeRenderPipelineState(
        descriptor: descriptor)
    } catch let error {
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

  static func createShadowPSO() -> MTLRenderPipelineState {
    let vertexFunction =
      Renderer.library?.makeFunction(name: "vertex_depth")
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = .invalid
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.vertexDescriptor = .defaultLayout
    return createPSO(descriptor: pipelineDescriptor)
  }

  static func makeFunctionConstants(hasSkeleton: Bool)
  -> MTLFunctionConstantValues {
    let functionConstants = MTLFunctionConstantValues()
    var property = hasSkeleton
    functionConstants.setConstantValue(
      &property,
      type: .bool,
      index: 0)
    return functionConstants
  }

  static func createForwardPSO(hasSkeleton: Bool = false)
  -> MTLRenderPipelineState {
    let functionConstants =
      makeFunctionConstants(hasSkeleton: hasSkeleton)
    let vertexFunction = try? Renderer.library?.makeFunction(
      name: "vertex_main",
      constantValues: functionConstants)
    let fragmentFunction = Renderer.library?.makeFunction(name: "fragment_PBR")
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat
      = Renderer.colorPixelFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.vertexDescriptor =
      MTLVertexDescriptor.defaultLayout
    return createPSO(descriptor: pipelineDescriptor)
  }

  static func createForwardTransparentPSO(hasSkeleton: Bool = false)
  -> MTLRenderPipelineState {
    let functionConstants =
      makeFunctionConstants(hasSkeleton: hasSkeleton)
    let vertexFunction = try? Renderer.library?.makeFunction(
      name: "vertex_main",
      constantValues: functionConstants)
    let fragmentFunction = Renderer.library?.makeFunction(name: "fragment_PBR")
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat
      = Renderer.colorPixelFormat
    let attachment = pipelineDescriptor.colorAttachments[0]
    attachment?.isBlendingEnabled = true
    attachment?.rgbBlendOperation = .add
    attachment?.sourceRGBBlendFactor = .one
    attachment?.destinationRGBBlendFactor = .oneMinusSourceAlpha

    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.vertexDescriptor =
      MTLVertexDescriptor.defaultLayout
    return createPSO(descriptor: pipelineDescriptor)
  }
}
