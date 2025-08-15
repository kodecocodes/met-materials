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

// swiftlint:disable implicitly_unwrapped_optional

import MetalKit

struct Submesh {
  let indexCount: Int
  let indexType: MTLIndexType
  let indexBuffer: MTLBuffer
  let indexBufferOffset: Int

  struct Textures {
    var baseColor: Int?
    var normal: Int?
    var opacity: Int?
  }
  var textures: Textures
  var material: Material
  var materialBuffer: MTLBuffer!

  var allTextures: [MTLTexture?] {
    [
      TextureController.getTexture(textures.baseColor),
      TextureController.getTexture(textures.normal),
      TextureController.getTexture(textures.opacity)
    ]}

  mutating func initializeMaterials() {
    let materialBufferSize = MemoryLayout<ShaderMaterial>.stride
    materialBuffer = Renderer.device.makeBuffer(
      length: materialBufferSize)
    materialBuffer.label = "Material Buffer"

    let textureIDs = allTextures.map { texture in
      texture?.gpuResourceID ?? MTLResourceID()
    }
    let pointer = materialBuffer.contents()
      .assumingMemoryBound(to: ShaderMaterial.self)
    pointer.pointee.material = material
    pointer.pointee.textures.0 = textureIDs[0]
    pointer.pointee.textures.1 = textureIDs[1]
    pointer.pointee.textures.2 = textureIDs[2]
  }
}

extension Submesh {
  init(mdlSubmesh: MDLSubmesh, mtkSubmesh: MTKSubmesh) {
    indexCount = mtkSubmesh.indexCount
    indexType = mtkSubmesh.indexType
    indexBuffer = mtkSubmesh.indexBuffer.buffer
    indexBufferOffset = mtkSubmesh.indexBuffer.offset
    textures = Textures(material: mdlSubmesh.material)
    material = Material(material: mdlSubmesh.material)
  }
}

private extension Submesh.Textures {
  init(material: MDLMaterial?) {
    baseColor = material?.texture(type: .baseColor)
    normal = material?.texture(type: .tangentSpaceNormal)
    opacity = material?.texture(type: .opacity)
  }
}

private extension MDLMaterialProperty {
  var textureName: String {
    stringValue ?? UUID().uuidString
  }
}

private extension MDLMaterial {
  func texture(type semantic: MDLMaterialSemantic) -> Int? {
    if let property = property(with: semantic),
    property.type == .texture,
    let mdlTexture = property.textureSamplerValue?.texture {
      let sRGB = semantic == .baseColor
      return TextureController.loadTexture(
        texture: mdlTexture,
        name: property.textureName,
        sRGB: sRGB)
    }
    return nil
  }
}

private extension Material {
  init(material: MDLMaterial?) {
    self.init()
    if let baseColor = material?.property(with: .baseColor),
      baseColor.type == .float3 {
      self.baseColor = baseColor.float3Value
    }
    opacity = 1.0
    if let opacity = material?.property(with: .opacity),
      opacity.type == .float3 || opacity.type == .float {
      self.opacity = opacity.floatValue
    }
  }
}

// swiftlint:enable implicitly_unwrapped_optional
