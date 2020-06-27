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

class TextureController {
  static var textures: [MTLTexture] = []
  
  static var heap: MTLHeap?
  
  static func addTexture(texture: MTLTexture?) -> Int? {
    guard let texture = texture else { return nil }
    TextureController.textures.append(texture)
    return TextureController.textures.count - 1
  }
  
  static func buildHeap() -> MTLHeap?  {
    let heapDescriptor = MTLHeapDescriptor()
    
    // add code here
    let descriptors = textures.map { texture in
      MTLTextureDescriptor.descriptor(from: texture)
    }
    let sizeAndAligns = descriptors.map {
      Renderer.device.heapTextureSizeAndAlign(descriptor: $0)
    }
    heapDescriptor.size = sizeAndAligns.reduce(0) {
      $0 + $1.size - ($1.size & ($1.align - 1)) + $1.align
    }
    if heapDescriptor.size == 0 {
      return nil
    }
    guard let heap = Renderer.device.makeHeap(descriptor: heapDescriptor) else {
      fatalError()
    }
    
    let heapTextures = descriptors.map { descriptor -> MTLTexture in
      descriptor.storageMode = heapDescriptor.storageMode
      return heap.makeTexture(descriptor: descriptor)!
    }
    
    guard
      let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
      let blitEncoder = commandBuffer.makeBlitCommandEncoder() else {
        fatalError()
      }
    zip(textures, heapTextures).forEach { (texture, heapTexture) in
      var region = MTLRegionMake2D(0, 0, texture.width, texture.height)
      for level in 0..<texture.mipmapLevelCount {
        for slice in 0..<texture.arrayLength {
          blitEncoder.copy(from: texture,
                           sourceSlice: slice,
                           sourceLevel: level,
                           sourceOrigin: region.origin,
                           sourceSize: region.size,
                           to: heapTexture,
                           destinationSlice: slice,
                           destinationLevel: level,
                           destinationOrigin: region.origin)
        }
        region.size.width /= 2
        region.size.height /= 2
      }
    }
    blitEncoder.endEncoding()
    commandBuffer.commit()
    TextureController.textures = heapTextures
    
    return heap
  }
}

