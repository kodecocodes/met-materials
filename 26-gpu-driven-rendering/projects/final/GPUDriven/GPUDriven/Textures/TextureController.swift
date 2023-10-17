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

// swiftlint:disable function_body_length

enum TextureController {
  static var textureIndex: [String: Int] = [:]
  static var textures: [MTLTexture] = []
  static var heap: MTLHeap?

  static func buildHeap() -> MTLHeap? {
    let heapDescriptor = MTLHeapDescriptor()

    let descriptors = textures.map { texture in
      texture.descriptor
    }

    let sizeAndAligns = descriptors.map { descriptor in
      Renderer.device.heapTextureSizeAndAlign(descriptor: descriptor)
    }
    heapDescriptor.size = sizeAndAligns.reduce(0) { total, sizeAndAlign in
      let size = sizeAndAlign.size
      let align = sizeAndAlign.align
      return total + size - (size & (align - 1)) + align
    }
    if heapDescriptor.size == 0 {
      return nil
    }

    guard let heap =
      Renderer.device.makeHeap(descriptor: heapDescriptor)
      else { return nil }

    let heapTextures = descriptors.map { descriptor -> MTLTexture in
      descriptor.storageMode = heapDescriptor.storageMode
      descriptor.cpuCacheMode = heapDescriptor.cpuCacheMode
      guard let texture = heap.makeTexture(descriptor: descriptor) else {
        fatalError("Failed to create heap textures")
      }
      return texture
    }

    guard
      let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
      let blitEncoder = commandBuffer.makeBlitCommandEncoder()
    else { return nil }
    zip(textures, heapTextures)
      .forEach { texture, heapTexture in
        heapTexture.label = texture.label
        var region =
          MTLRegionMake2D(0, 0, texture.width, texture.height)
        for level in 0..<texture.mipmapLevelCount {
          for slice in 0..<texture.arrayLength {
            blitEncoder.copy(
              from: texture,
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
    Self.textures = heapTextures
    return heap
  }

  static func texture(name: String) -> Int? {
    if let index = textureIndex[name] {
      return index
    }
    if let texture = loadTexture(name: name) {
      return store(texture: texture, name: name)
    }
    return nil
  }

  static func store(texture: MTLTexture?, name: String) -> Int? {
    guard let texture else { return nil }
    texture.label = name
    if let index = textureIndex[name] {
      return index
    }
    textures.append(texture)
    let index = textures.count - 1
    textureIndex[name] = index
    return index
  }

  static func getTexture(_ index: Int?) -> MTLTexture? {
    if let index = index {
      return textures[index]
    }
    return nil
  }

  static func loadTexture(texture: MDLTexture, name: String) -> Int? {
    let textureLoader = MTKTextureLoader(device: Renderer.device)
    let textureLoaderOptions: [MTKTextureLoader.Option: Any] =
      [.origin: MTKTextureLoader.Origin.bottomLeft,
       .generateMipmaps: true]
    let texture = try? textureLoader.newTexture(
      texture: texture,
      options: textureLoaderOptions)
    return store(texture: texture, name: name)
  }

  static func loadTexture(name: String) -> MTLTexture? {
    let textureLoader = MTKTextureLoader(device: Renderer.device)
    return try? textureLoader.newTexture(
      name: name,
      scaleFactor: 1.0,
      bundle: Bundle.main,
      options: nil)
  }

  // load a cube texture
  static func loadCubeTexture(imageName: String) -> MTLTexture? {
    let textureLoader = MTKTextureLoader(device: Renderer.device)
    // asset catalog loading
    if let texture = MDLTexture(cubeWithImagesNamed: [imageName]) {
      let options: [MTKTextureLoader.Option: Any] = [
        .origin: MTKTextureLoader.Origin.topLeft,
        .SRGB: false,
        .generateMipmaps: false
      ]
      return try? textureLoader.newTexture(
        texture: texture,
        options: options)
    }
    // bundle file loading
    let texture = try? textureLoader.newTexture(
      name: imageName,
      scaleFactor: 1.0,
      bundle: .main)
    return texture
  }
}
// swiftlint:enable function_body_length
