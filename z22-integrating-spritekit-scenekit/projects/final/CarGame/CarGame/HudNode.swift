//
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


import Foundation
import SpriteKit

class HudNode: Node {
  let skScene: Hud
  let skRenderer: SKRenderer
  let renderPass: RenderPass
  var outputTexture: MTLTexture
  let kernel: CIBlendKernel

  init(name: String, size: CGSize) {
    guard let skScene = SKScene(fileNamed: name) as? Hud
      else {
        fatalError("No scene found")
    }
    self.skScene = skScene
    skRenderer = SKRenderer(device: Renderer.device)
    skRenderer.scene = skScene
    renderPass = RenderPass(name: name, size: size)
    
    outputTexture = RenderPass.buildTexture(size: size,
                                            label: "output texture",
                                            pixelFormat: renderPass.texture.pixelFormat,
                                            usage: [.shaderWrite])
    let url = Bundle.main.url(forResource: "CIBlend",
                              withExtension: "metallib")!
    do {
      let data = try Data(contentsOf: url)
      kernel = try CIBlendKernel(functionName: "hudBlend",
                                 fromMetalLibraryData: data)
    } catch {
      fatalError("Kernel not found")
    }
    super.init()
    sceneSizeWillChange(to: size)
    self.name = name
  }
  
  func sceneSizeWillChange(to size: CGSize) {
    skScene.isPaused = false
    skScene.size = size
    renderPass.updateTextures(size: size)
  }
  
  override func update(deltaTime: Float) {
    skRenderer.update(atTime: CACurrentMediaTime())
    guard let commandBuffer = Renderer.commandBuffer else {
      return
    }
    let viewPort = CGRect(origin: .zero, size: skScene.size)
    skRenderer.render(withViewport: viewPort,
                      commandBuffer: commandBuffer,
                      renderPassDescriptor: renderPass.descriptor)
  }
}

extension HudNode: PostProcess {
  func postProcess(inputTexture: MTLTexture) {
    if inputTexture.width != outputTexture.width ||
      inputTexture.height != outputTexture.height {
      let size = CGSize(width: inputTexture.width,
                        height: inputTexture.height)
      outputTexture = RenderPass.buildTexture(size: size,
                                              label: "output texture",
                                              pixelFormat: renderPass.texture.pixelFormat,
                                              usage: [.shaderWrite])
    }
    guard let commandBuffer = Renderer.commandBuffer else { return }
    let drawableImage = CIImage(mtlTexture: inputTexture)!
    
    let hudImage = CIImage(mtlTexture: renderPass.texture)!
    let extent = hudImage.extent
    let arguments = [hudImage, drawableImage]
    let outputImage = kernel.apply(extent: extent, arguments: arguments)!

    let context = CIContext(mtlDevice: Renderer.device)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    context.render(outputImage, to: outputTexture,
                   commandBuffer: commandBuffer,
                   bounds: outputImage.extent,
                   colorSpace: colorSpace)
    let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
    let origin = MTLOrigin(x: 0, y: 0, z: 0)
    let size = MTLSize(width: inputTexture.width, height: inputTexture.height, depth: 1)
    blitEncoder.copy(from: outputTexture, sourceSlice: 0, sourceLevel: 0,
                     sourceOrigin: origin, sourceSize: size,
                     to: inputTexture, destinationSlice: 0,
                     destinationLevel: 0, destinationOrigin: origin)
    blitEncoder.endEncoding()
  }
}

