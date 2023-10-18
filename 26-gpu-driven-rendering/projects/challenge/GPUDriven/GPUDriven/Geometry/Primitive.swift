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
// swiftlint:disable force_try

enum Primitive {
  case plane, sphere
}

extension Model {
  convenience init(name: String, primitiveType: Primitive) {
    let mdlMesh = Self.createMesh(primitiveType: primitiveType)
    mdlMesh.vertexDescriptor = MDLVertexDescriptor.defaultLayout

    // this app expects index type .uint32
    // primitives are created with .uint16
    let mtkMesh: MTKMesh
    if let submeshes = mdlMesh.submeshes as? [MDLSubmesh],
       !submeshes.filter({ $0.indexType == .uint16 }).isEmpty {
        mtkMesh = mdlMesh.convertIndexType(from: .uint16, to: .uint32)
      } else {
        mtkMesh = try! MTKMesh(mesh: mdlMesh, device: Renderer.device)
    }

    let mesh = Mesh(mdlMesh: mdlMesh, mtkMesh: mtkMesh)
    self.init()
    self.meshes = [mesh]
    self.name = name
  }

  static func createMesh(primitiveType: Primitive) -> MDLMesh {
    let allocator = MTKMeshBufferAllocator(device: Renderer.device)
    switch primitiveType {
    case .plane:
      return MDLMesh(
        planeWithExtent: [1, 1, 1],
        segments: [4, 4],
        geometryType: .triangles,
        allocator: allocator)
    case .sphere:
      return MDLMesh(
        sphereWithExtent: [1, 1, 1],
        segments: [30, 30],
        inwardNormals: false,
        geometryType: .triangles,
        allocator: allocator)
    }
  }

}

// swiftlint:enable force_try

private extension MDLMesh {
  func convertIndexType(from fromType: MDLIndexBitDepth, to toType: MDLIndexBitDepth)
  -> MTKMesh {
    var newSubmeshes: [MDLSubmesh] = []
    if let submeshes = submeshes as? [MDLSubmesh] {
      for submesh in submeshes {
        let indexBuffer = submesh.indexBuffer(asIndexType: toType)
        let newSubmesh = MDLSubmesh(
          name: submesh.name,
          indexBuffer: indexBuffer,
          indexCount: submesh.indexCount,
          indexType: toType,
          geometryType: submesh.geometryType,
          material: submesh.material)
        newSubmeshes.append(newSubmesh)
      }
    }
    let mdlMesh = MDLMesh(
      vertexBuffers: vertexBuffers,
      vertexCount: vertexCount,
      descriptor: vertexDescriptor,
      submeshes: newSubmeshes)
    do {
      return try MTKMesh(mesh: mdlMesh, device: Renderer.device)
    } catch {
      fatalError("Unable to create MTKMesh")
    }
  }
}
