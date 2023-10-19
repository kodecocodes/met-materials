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
import MetalPerformanceShaders

// swiftlint:disable implicitly_unwrapped_optional

struct Bloom {
  let label = "Bloom Filter"
  var outputTexture: MTLTexture!
  var finalTexture: MTLTexture!

  mutating func resize(view: MTKView, size: CGSize) {
    outputTexture = TextureController.makeTexture(
      size: size,
      pixelFormat: view.colorPixelFormat,
      label: "Output Texture",
      usage: [.shaderRead, .shaderWrite])
    finalTexture = TextureController.makeTexture(
      size: size,
      pixelFormat: view.colorPixelFormat,
      label: "Final Texture",
      usage: [.shaderRead, .shaderWrite])
  }

  mutating func postProcess(
    view: MTKView,
    commandBuffer: MTLCommandBuffer
  ) {
    guard
      let drawableTexture =
        view.currentDrawable?.texture else { return }

    // Brightness
    let brightness = MPSImageThresholdToZero(
      device: Renderer.device,
      thresholdValue: 0.95,
      linearGrayColorTransform: nil)
    brightness.label = "MPS brightness"
    brightness.encode(
      commandBuffer: commandBuffer,
      sourceTexture: drawableTexture,
      destinationTexture: outputTexture)
    // Gaussian Blur
    let blur = MPSImageGaussianBlur(
      device: Renderer.device,
      sigma: 5.0)
    blur.label = "MPS blur"
    blur.encode(
      commandBuffer: commandBuffer,
      inPlaceTexture: &outputTexture,
      fallbackCopyAllocator: nil)

    // Combine original render and filtered render
    let add = MPSImageAdd(device: Renderer.device)
    add.label = "Add original image to blur"
    add.encode(
      commandBuffer: commandBuffer,
      primaryTexture: drawableTexture,
      secondaryTexture: outputTexture,
      destinationTexture: finalTexture)

    guard let blitEncoder = commandBuffer.makeBlitCommandEncoder()
      else { return }
    blitEncoder.label = "Copy bloom to drawable"
    let origin = MTLOrigin(x: 0, y: 0, z: 0)
    let size = MTLSize(
      width: drawableTexture.width,
      height: drawableTexture.height,
      depth: 1)
    blitEncoder.copy(
      from: finalTexture,
      sourceSlice: 0,
      sourceLevel: 0,
      sourceOrigin: origin,
      sourceSize: size,
      to: drawableTexture,
      destinationSlice: 0,
      destinationLevel: 0,
      destinationOrigin: origin)
    blitEncoder.endEncoding()
  }
}
// swiftlint:enable implicitly_unwrapped_optional
