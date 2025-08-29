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
import MetalFX

struct UpscalePass {
  var label: String
  var descriptor: MTLRenderPassDescriptor
  var spatialScaler: MTLFXSpatialScaler?
  var currentFrameColor: MTLTexture?
  var currentFrameUpscaledColor: MTLTexture?
  var currentFrameDepth: MTLTexture?
  var currentFrameUpscaledDepth: MTLTexture?
  var lastCreatedSize: CGSize?

  init(view: MTKView) {
    label = "UpscalePass"
    descriptor = MTLRenderPassDescriptor()
  }

  mutating func resize(view: MTKView, size: CGSize) {
    let spatialDesc = MTLFXSpatialScalerDescriptor()
    spatialDesc.inputWidth = Int(size.width / kUpscaleAmount)
    spatialDesc.inputHeight = Int(size.height / kUpscaleAmount)
    spatialDesc.outputWidth = Int(size.width)
    spatialDesc.outputHeight = Int(size.height)
    spatialDesc.colorTextureFormat = view.colorPixelFormat
    spatialDesc.outputTextureFormat = view.colorPixelFormat
    spatialDesc.colorProcessingMode = .perceptual
    spatialScaler = spatialDesc.makeSpatialScaler(device: Renderer.device)

    currentFrameUpscaledColor = TextureController.makeTexture(
      size: size,
      pixelFormat: view.colorPixelFormat,
      label: "Upscaled Frame Color")
    currentFrameColor = TextureController.makeTexture(
      size: size / kUpscaleAmount,
      pixelFormat: view.colorPixelFormat,
      label: "Current Frame Color",
      storageMode: .private,
      usage: [.renderTarget, .shaderRead, .shaderWrite])
    currentFrameUpscaledDepth = TextureController.makeTexture(
      size: size,
      pixelFormat: view.depthStencilPixelFormat,
      label: "Upscaled Frame Depth")
    currentFrameDepth = TextureController.makeTexture(
      size: size / kUpscaleAmount,
      pixelFormat: view.depthStencilPixelFormat,
      label: "Current Frame Depth")
  }

  func update() {
    descriptor.colorAttachments[0].texture = currentFrameColor
    descriptor.colorAttachments[0].loadAction = .clear
    descriptor.colorAttachments[0].storeAction = .store
    descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
    descriptor.depthAttachment.loadAction = .clear
    descriptor.depthAttachment.storeAction = .dontCare
    descriptor.depthAttachment.clearDepth = 1.0
    descriptor.depthAttachment.texture = currentFrameDepth
  }

  func upscale(commandBuffer: MTLCommandBuffer) {
    guard let spatialScaler,
      let inputTexture = currentFrameColor,
      let outputTexture = currentFrameUpscaledColor else { return }
    spatialScaler.colorTexture = inputTexture
    spatialScaler.outputTexture = outputTexture
    spatialScaler.encode(commandBuffer: commandBuffer)
  }
}
