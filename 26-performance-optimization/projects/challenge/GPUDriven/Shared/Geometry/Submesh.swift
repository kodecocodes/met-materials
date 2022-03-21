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

// swiftlint:disable implicitly_unwrapped_optional

import MetalKit

struct Submesh {
  let indexCount: Int
  let indexType: MTLIndexType
  let indexBuffer: MTLBuffer
  let indexBufferOffset: Int
  var materialsBuffer: MTLBuffer!

  struct Textures {
    let baseColor: Int?
    let normal: Int?
    let roughness: Int?
    let metallic: Int?
    let ambientOcclusion: Int?
    let opacity: Int?
  }

  var modelIndexBuffer: MTLBuffer!
  let textures: Textures
  var material: Material
  var transparency: Bool {
    textures.opacity != nil || material.opacity < 1.0
  }
  var allTextures: [MTLTexture?] {
    [
      TextureController.getTexture(textures.baseColor),
      TextureController.getTexture(textures.normal),
      TextureController.getTexture(textures.roughness),
      TextureController.getTexture(textures.metallic),
      TextureController.getTexture(textures.ambientOcclusion),
      TextureController.getTexture(textures.opacity)
    ]}

  mutating func initializeMaterials() {
    guard let fragment =
      Renderer.library.makeFunction(name: "fragment_PBR") else {
        fatalError("Fragment function does not exist")
      }
    let materialEncoder = fragment.makeArgumentEncoder(
      bufferIndex: MaterialBuffer.index)
    materialsBuffer = Renderer.device.makeBuffer(
      length: materialEncoder.encodedLength,
      options: [])
    materialsBuffer?.label = "Submesh Material Argument Buffer"
    // 1
    materialEncoder.setArgumentBuffer(materialsBuffer, offset: 0)
    // 2
    let range = Range(BaseColor.index...OpacityTexture.index)
    materialEncoder.setTextures(allTextures, range: range)
    // 3
    let index = OpacityTexture.index + 1
    let address = materialEncoder.constantData(at: index)
    address.copyMemory(
      from: &material,
      byteCount: MemoryLayout<Material>.stride)
  }
}

extension Submesh {
  init(mdlSubmesh: MDLSubmesh, mtkSubmesh: MTKSubmesh) {
    indexCount = mtkSubmesh.indexCount
    indexType = mtkSubmesh.indexType
    indexBuffer = mtkSubmesh.indexBuffer.buffer
    indexBufferOffset = mtkSubmesh.indexBuffer.offset
    indexBuffer.label = "Submesh Index Buffer"
    textures = Textures(material: mdlSubmesh.material)
    material = Material(material: mdlSubmesh.material)
    modelIndexBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<UInt32>.stride,
      options: [])
  }
}

private extension Submesh.Textures {
  init(material: MDLMaterial?) {
    func property(with semantic: MDLMaterialSemantic) -> Int? {
      guard let property = material?.property(with: semantic),
        property.type == .string,
        let filename = property.stringValue,
        let texture =
          TextureController.texture(filename: filename)
        else {
          if let property = material?.property(with: semantic),
            property.type == .texture,
            let mdlTexture = property.textureSamplerValue?.texture {
            return try? TextureController.loadTexture(texture: mdlTexture)
          }
          return nil
        }
      return texture
    }
    baseColor = property(with: MDLMaterialSemantic.baseColor)
    normal = property(with: .tangentSpaceNormal)
    roughness = property(with: .roughness)
    metallic = property(with: .metallic)
    ambientOcclusion = property(with: .ambientOcclusion)
    opacity = property(with: .opacity)
  }
}

private extension Material {
  init(material: MDLMaterial?) {
    self.init()
    if let baseColor = material?.property(with: .baseColor),
      baseColor.type == .float3 {
      self.baseColor = baseColor.float3Value
    }
    if let specular = material?.property(with: .specular),
      specular.type == .float3 {
      self.specularColor = specular.float3Value
    }
    if let shininess = material?.property(with: .specularExponent),
      shininess.type == .float {
      self.shininess = shininess.floatValue
    }
    roughness = 1
    if let roughness = material?.property(with: .roughness),
      roughness.type == .float3 {
      self.roughness = roughness.floatValue
    }
    metallic = 0
    if let metallic = material?.property(with: .metallic),
      metallic.type == .float3 {
      self.metallic = metallic.floatValue
    }
    ambientOcclusion = 1.0
    if let ambientOcclusion = material?.property(with: .ambientOcclusion),
      ambientOcclusion.type == .float3 {
      self.ambientOcclusion = ambientOcclusion.floatValue
    }
    opacity = 1.0
    if let opacity = material?.property(with: .opacity),
      opacity.type == .float {
      self.opacity = opacity.floatValue
    }
  }
}
