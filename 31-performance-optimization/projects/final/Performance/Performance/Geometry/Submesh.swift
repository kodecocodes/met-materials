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

struct Submesh {
  let indexCount: Int
  let indexType: MTLIndexType
  let indexBuffer: MTLBuffer
  let indexBufferOffset: Int

  struct Textures {
    var baseColor: Int?
    var normal: Int?
    var roughness: Int?
    var metallic: Int?
    var aoTexture: Int?
    var opacity: Int?
  }

  var textures: Textures
  var material: Material

  var transparency: Bool {
    return textures.opacity != nil || material.opacity < 1.0
  }

  var allTextures: [MTLTexture?] {
    [
      TextureController.getTexture(textures.baseColor),
      TextureController.getTexture(textures.normal),
      TextureController.getTexture(textures.roughness),
      TextureController.getTexture(textures.metallic),
      TextureController.getTexture(textures.aoTexture),
      TextureController.getTexture(textures.opacity)
    ]}
  var materialsBuffer: MTLBuffer!
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

  mutating func initializeMaterials() {
    guard let fragment =
      Renderer.library.makeFunction(name: "fragment_IBL") else {
        fatalError("Fragment function does not exist")
      }
    let materialEncoder = fragment.makeArgumentEncoder(
      bufferIndex: MaterialBuffer.index)
    materialsBuffer = Renderer.device.makeBuffer(
      length: materialEncoder.encodedLength,
      options: [])

    materialEncoder.setArgumentBuffer(materialsBuffer, offset: 0)
    let range = Range(BaseColor.index...OpacityTexture.index)
    materialEncoder.setTextures(allTextures, range: range)
    let index = OpacityTexture.index + 1
    let address = materialEncoder.constantData(at: index)
    address.copyMemory(
      from: &material,
      byteCount: MemoryLayout<Material>.stride)
  }
}

private extension Submesh.Textures {
  init(material: MDLMaterial?) {
    baseColor = material?.texture(type: .baseColor)
    roughness = material?.texture(type: .roughness)
    normal = material?.texture(type: .tangentSpaceNormal)
    metallic = material?.texture(type: .metallic)
    aoTexture = material?.texture(type: .ambientOcclusion)
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
      return TextureController.loadTexture(
        texture: mdlTexture,
        name: NSString(string: property.textureName).lastPathComponent)
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
    if let roughness = material?.property(with: .roughness),
      roughness.type == .float {
      self.roughness = roughness.floatValue
    }
    if let metallic = material?.property(with: .metallic),
       metallic.type == .float {
      self.metallic = metallic.floatValue
    }
    self.ambientOcclusion = 1
    opacity = 1.0
    if let opacity = material?.property(with: .opacity),
       opacity.type == .float3 || opacity.type == .float {
      self.opacity = opacity.floatValue
    }
  }
}
