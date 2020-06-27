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


import MetalKit

class RenderPass {
  var descriptor: MTLRenderPassDescriptor
  var texture: MTLTexture
  var depthTexture: MTLTexture
  let name: String
  
  init(name: String, size: CGSize) {
    self.name = name
    texture = RenderPass.buildTexture(size: size, label: name,
                                      pixelFormat: .bgra8Unorm)
    depthTexture = RenderPass.buildTexture(size: size, label: name,
                                           pixelFormat: .depth32Float)
    descriptor = RenderPass.setupRenderPassDescriptor(texture: texture,
                                                      depthTexture: depthTexture)
  }
  
  func updateTextures(size: CGSize) {
    texture = RenderPass.buildTexture(size: size, label: name,
                                      pixelFormat: .bgra8Unorm)
    depthTexture = RenderPass.buildTexture(size: size, label: name,
                                           pixelFormat: .depth32Float)
    descriptor = RenderPass.setupRenderPassDescriptor(texture: texture,
                                                      depthTexture: depthTexture)
  }
  
  static func setupRenderPassDescriptor(texture: MTLTexture,
                                        depthTexture: MTLTexture) -> MTLRenderPassDescriptor {
    let descriptor = MTLRenderPassDescriptor()
    descriptor.setUpColorAttachment(position: 0, texture: texture)
    descriptor.setUpDepthAttachment(texture: depthTexture)
    return descriptor
  }
  
  static func buildTexture(size: CGSize,
                           label: String,
                           pixelFormat: MTLPixelFormat) -> MTLTexture {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat,
                                                              width: Int(size.width * 0.5),
                                                              height: Int(size.height * 0.5),
                                                              mipmapped: false)
    descriptor.sampleCount = 1
    descriptor.storageMode = .private
    descriptor.textureType = .type2D
    descriptor.usage = [.renderTarget, .shaderRead]
    guard let texture = Renderer.device.makeTexture(descriptor: descriptor) else {
      fatalError("Texture not created")
    }
    texture.label = label
    return texture
  }
 }

private extension MTLRenderPassDescriptor {
  func setUpDepthAttachment(texture: MTLTexture) {
    depthAttachment.texture = texture
    depthAttachment.loadAction = .clear
    depthAttachment.storeAction = .store
    depthAttachment.clearDepth = 1
  }
  
  func setUpColorAttachment(position: Int, texture: MTLTexture) {
    let attachment: MTLRenderPassColorAttachmentDescriptor = colorAttachments[position]
    attachment.texture = texture
    attachment.loadAction = .clear
    attachment.storeAction = .store
    attachment.clearColor = MTLClearColorMake(0.73, 0.92, 1, 1)
  }
}
