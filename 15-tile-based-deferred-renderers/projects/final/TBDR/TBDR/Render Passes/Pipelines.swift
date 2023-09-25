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

  static func createForwardPSO(colorPixelFormat: MTLPixelFormat) -> MTLRenderPipelineState {
    let vertexFunction = Renderer.library?.makeFunction(name: "vertex_main")
    let fragmentFunction = Renderer.library?.makeFunction(name: "fragment_main")
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.vertexDescriptor =
      MTLVertexDescriptor.defaultLayout
    return createPSO(descriptor: pipelineDescriptor)
  }

  static func createGBufferPSO(
    colorPixelFormat: MTLPixelFormat,
    tiled: Bool = false
  ) -> MTLRenderPipelineState {
    let vertexFunction = Renderer.library?.makeFunction(name: "vertex_main")
    let fragmentFunction = Renderer.library?.makeFunction(name: "fragment_gBuffer")
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat
      = .invalid
    if tiled {
      pipelineDescriptor.colorAttachments[0].pixelFormat
        = colorPixelFormat
    }
    pipelineDescriptor.setGBufferPixelFormats()
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    if !tiled {
      pipelineDescriptor.depthAttachmentPixelFormat
        = .depth32Float_stencil8
      pipelineDescriptor.stencilAttachmentPixelFormat
        = .depth32Float_stencil8
    }
    pipelineDescriptor.vertexDescriptor =
      MTLVertexDescriptor.defaultLayout
    return createPSO(descriptor: pipelineDescriptor)
  }

  static func createSunLightPSO(
    colorPixelFormat: MTLPixelFormat,
    tiled: Bool = false
  ) -> MTLRenderPipelineState {
    let vertexFunction = Renderer.library?.makeFunction(name: "vertex_quad")
    let fragment = tiled ? "fragment_tiled_deferredSun" : "fragment_deferredSun"
    let fragmentFunction = Renderer.library?.makeFunction(name: fragment)
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
    if tiled {
      pipelineDescriptor.setGBufferPixelFormats()
    }
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    if !tiled {
      pipelineDescriptor.depthAttachmentPixelFormat
        = .depth32Float_stencil8
      pipelineDescriptor.stencilAttachmentPixelFormat
        = .depth32Float_stencil8
    }
    return createPSO(descriptor: pipelineDescriptor)
  }

  static func createPointLightPSO(
    colorPixelFormat: MTLPixelFormat,
    tiled: Bool = false
  ) -> MTLRenderPipelineState {
    let vertexFunction = Renderer.library?.makeFunction(name: "vertex_pointLight")
    let fragment = tiled ? "fragment_tiled_pointLight" : "fragment_pointLight"
    let fragmentFunction = Renderer.library?.makeFunction(name: fragment)
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
    if tiled {
      pipelineDescriptor.setGBufferPixelFormats()
    }
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    if !tiled {
      pipelineDescriptor.depthAttachmentPixelFormat
        = .depth32Float_stencil8
      pipelineDescriptor.stencilAttachmentPixelFormat
        = .depth32Float_stencil8
    }
    pipelineDescriptor.vertexDescriptor =
      MTLVertexDescriptor.defaultLayout
    let attachment = pipelineDescriptor.colorAttachments[0]
    attachment?.isBlendingEnabled = true
    attachment?.rgbBlendOperation = .add
    attachment?.alphaBlendOperation = .add
    attachment?.sourceRGBBlendFactor = .one
    attachment?.sourceAlphaBlendFactor = .one
    attachment?.destinationRGBBlendFactor = .one
    attachment?.destinationAlphaBlendFactor = .zero
    attachment?.sourceRGBBlendFactor = .one
    attachment?.sourceAlphaBlendFactor = .one
    return createPSO(descriptor: pipelineDescriptor)
  }

}

extension MTLRenderPipelineDescriptor {
  func setGBufferPixelFormats() {
    colorAttachments[RenderTargetAlbedo.index]
      .pixelFormat = .bgra8Unorm
    colorAttachments[RenderTargetNormal.index]
      .pixelFormat = .rgba16Float
    colorAttachments[RenderTargetPosition.index]
      .pixelFormat = .rgba16Float
  }
}
