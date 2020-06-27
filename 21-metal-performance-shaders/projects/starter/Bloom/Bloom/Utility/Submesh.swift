/**
 * Copyright (c) 2018 Razeware LLC
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
  var submesh: MTKSubmesh
  var material = Material()
  
  init(submesh: MTKSubmesh, mdlSubmesh: MDLSubmesh) {
    self.submesh = submesh
    material = createMaterialFrom(submesh: mdlSubmesh)
  }
  
  func createMaterialFrom(submesh: MDLSubmesh) -> Material {
    var material = Material()
    if let baseColor = submesh.material?.propertyNamed("baseColor"),
      baseColor.type == .float3 {
      material.baseColor = [Float(baseColor.float3Value.x),
                            Float(baseColor.float3Value.y),
                            Float(baseColor.float3Value.z)]
    }
    if let specular = submesh.material?.propertyNamed("specular") {
      if specular.type == .float3 {
        material.specularColor = float3(Float(specular.float4Value.x),
                                        Float(specular.float4Value.y),
                                        Float(specular.float4Value.z))
      }
    }
    if let shininess = submesh.material?.propertyNamed("specularExponent") {
      if shininess.type == .float {
        material.shininess = shininess.floatValue
      }
    }
    if let emission = submesh.material?.propertyNamed("emission") {
      if emission.type == .float3 {
        material.emissionColor = emission.float3Value
      }
    }
    return material
  }
}
