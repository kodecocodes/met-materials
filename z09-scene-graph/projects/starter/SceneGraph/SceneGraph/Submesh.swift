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

class Submesh {
  var mtkSubmesh: MTKSubmesh
  
  struct Textures {
    let baseColor: MTLTexture?
    let normal: MTLTexture?
    let roughness: MTLTexture?
    let metallic: MTLTexture?
    let ao: MTLTexture?
  }
  
  let textures: Textures
  let material: Material
  let pipelineState: MTLRenderPipelineState
  
  init(mdlSubmesh: MDLSubmesh, mtkSubmesh: MTKSubmesh, hasSkeleton: Bool) {
    self.mtkSubmesh = mtkSubmesh
    textures = Textures(material: mdlSubmesh.material)
    material = Material(material: mdlSubmesh.material)
    pipelineState =
      Submesh.makePipelineState(textures: textures,
                                hasSkeleton: hasSkeleton)
    
  }
}

// Pipeline state
private extension Submesh {
  static func makeFunctionConstants(textures: Textures)
    -> MTLFunctionConstantValues {
      let functionConstants = MTLFunctionConstantValues()
      var property = textures.baseColor != nil
      functionConstants.setConstantValue(&property, type: .bool, index: 0)
      property = textures.normal != nil
      functionConstants.setConstantValue(&property, type: .bool, index: 1)
      property = textures.roughness != nil
      functionConstants.setConstantValue(&property, type: .bool, index: 2)
      property = textures.metallic != nil
      functionConstants.setConstantValue(&property, type: .bool, index: 3)
      property = textures.ao != nil
      functionConstants.setConstantValue(&property, type: .bool, index: 4)
      return functionConstants
  }
  
  static func makeVertexFunctionConstants(hasSkeleton: Bool) -> MTLFunctionConstantValues {
    let functionConstants = MTLFunctionConstantValues()
    var addSkeleton = hasSkeleton
    functionConstants.setConstantValue(&addSkeleton, type: .bool, index: 5)
    return functionConstants
  }
  
  static func makePipelineState(textures: Textures,
                                hasSkeleton: Bool)
    -> MTLRenderPipelineState {
      let functionConstants = makeFunctionConstants(textures: textures)
    
    let library = Renderer.library
      let vertexFunction: MTLFunction?
      let fragmentFunction: MTLFunction?
    do {
      let constantValues =
        makeVertexFunctionConstants(hasSkeleton: hasSkeleton)
      vertexFunction =
        try library?.makeFunction(name: "vertex_main",
                                  constantValues: constantValues)
      fragmentFunction = try library?.makeFunction(name: "fragment_mainPBR",
                                                   constantValues: functionConstants)
    } catch {
      fatalError("No Metal function exists")
    }
    
    var pipelineState: MTLRenderPipelineState
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    
    let vertexDescriptor = Model.vertexDescriptor
    pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
    pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.colorPixelFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    do {
      pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
    return pipelineState
  }
}


extension Submesh: Texturable {}

private extension Submesh.Textures {
  init(material: MDLMaterial?) {
    func property(with semantic: MDLMaterialSemantic) -> MTLTexture? {
      guard let property = material?.property(with: semantic),
        property.type == .string,
        let filename = property.stringValue,
        let texture = try? Submesh.loadTexture(imageName: filename)
        else {
          if let property = material?.property(with: semantic),
            property.type == .texture,
            let mdlTexture = property.textureSamplerValue?.texture {
            return try? Submesh.loadTexture(texture: mdlTexture)
          }
          return nil
      }
      return texture
    }
    baseColor = property(with: MDLMaterialSemantic.baseColor)
    normal = property(with: .tangentSpaceNormal)
    roughness = property(with: .roughness)
    metallic = property(with: .metallic)
    ao = property(with: .ambientOcclusion)
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
    if let roughness = material?.property(with: .roughness),
      roughness.type == .float3 {
      self.roughness = roughness.floatValue
    }
  }
}

