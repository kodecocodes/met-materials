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

class Model: Node {
  
  let meshes: [Mesh]
  var tiling: UInt32 = 1
  let samplerState: MTLSamplerState?
  static var vertexDescriptor: MDLVertexDescriptor = MDLVertexDescriptor.defaultVertexDescriptor

  init(name: String) {
    guard
      let assetUrl = Bundle.main.url(forResource: name, withExtension: nil) else {
        fatalError("Model: \(name) not found")
    }
    let allocator = MTKMeshBufferAllocator(device: Renderer.device)
    let asset = MDLAsset(url: assetUrl,
                         vertexDescriptor: MDLVertexDescriptor.defaultVertexDescriptor,
                         bufferAllocator: allocator)
    var mtkMeshes: [MTKMesh] = []
    let mdlMeshes = asset.childObjects(of: MDLMesh.self) as! [MDLMesh]
    _ = mdlMeshes.map { mdlMesh in
      mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed:
        MDLVertexAttributeTextureCoordinate,
                              tangentAttributeNamed: MDLVertexAttributeTangent,
                              bitangentAttributeNamed: MDLVertexAttributeBitangent)
      Model.vertexDescriptor = mdlMesh.vertexDescriptor
      mtkMeshes.append(try! MTKMesh(mesh: mdlMesh, device: Renderer.device))
    }

    meshes = zip(mdlMeshes, mtkMeshes).map {
      Mesh(mdlMesh: $0.0, mtkMesh: $0.1)
    }
    samplerState = Model.buildSamplerState()
    super.init()
    self.name = name
  }
  
  private static func buildSamplerState() -> MTLSamplerState? {
    let descriptor = MTLSamplerDescriptor()
    descriptor.sAddressMode = .repeat
    descriptor.tAddressMode = .repeat
    descriptor.mipFilter = .linear
    descriptor.maxAnisotropy = 8
    let samplerState =
      Renderer.device.makeSamplerState(descriptor: descriptor)
    return samplerState
  }
}



