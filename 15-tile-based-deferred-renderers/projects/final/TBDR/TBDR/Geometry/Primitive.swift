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
  case plane, sphere, icosahedron
}

extension Model {
  convenience init(name: String, primitiveType: Primitive) {
    let mdlMesh = Self.createMesh(primitiveType: primitiveType)
    mdlMesh.vertexDescriptor = MDLVertexDescriptor.defaultLayout
    mdlMesh.addTangentBasis(
      forTextureCoordinateAttributeNamed:
        MDLVertexAttributeTextureCoordinate,
      tangentAttributeNamed: MDLVertexAttributeTangent,
      bitangentAttributeNamed: MDLVertexAttributeBitangent)

    let mtkMesh = try! MTKMesh(mesh: mdlMesh, device: Renderer.device)
    let mesh = Mesh(mdlMesh: mdlMesh, mtkMesh: mtkMesh)
    self.init()
    self.meshes = [mesh]
    self.name = name
  }

  static func createMesh(primitiveType: Primitive) -> MDLMesh {
    let allocator = MTKMeshBufferAllocator(device: Renderer.device)
    switch primitiveType {
    case .icosahedron:
      return MDLMesh(
        icosahedronWithExtent: [1, 1, 1],
        inwardNormals: false,
        geometryType: .triangles,
        allocator: allocator)
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
