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

class Model: Transformable {
  var transform = Transform()
  var meshes: [Mesh] = []
  var name: String = "Untitled"
  var tiling: UInt32 = 1

  init() { }

  init(name: String) {
    guard let assetURL = Bundle.main.url(
      forResource: name,
      withExtension: nil) else {
      fatalError("Model \(name) not found")
    }
    let allocator = MTKMeshBufferAllocator(device: Renderer.device)
    let asset = MDLAsset(
      url: assetURL,
      vertexDescriptor: .defaultLayout,
      bufferAllocator: allocator)
    asset.loadTextures()
    var mtkMeshes: [MTKMesh] = []
    let mdlMeshes =
      asset.childObjects(of: MDLMesh.self) as? [MDLMesh] ?? []
    _ = mdlMeshes.map { mdlMesh in
      mdlMesh.addTangentBasis(
        forTextureCoordinateAttributeNamed:
          MDLVertexAttributeTextureCoordinate,
        tangentAttributeNamed: MDLVertexAttributeTangent,
        bitangentAttributeNamed: MDLVertexAttributeBitangent)
      mtkMeshes.append(
        try! MTKMesh(
          mesh: mdlMesh,
          device: Renderer.device))
    }
    meshes = zip(mdlMeshes, mtkMeshes).map {
      Mesh(mdlMesh: $0.0, mtkMesh: $0.1)
    }
    self.name = name
  }

  func convertMesh() {
    guard let commandBuffer =
      Renderer.commandQueue.makeCommandBuffer(),
      let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        else { return }
    let startTime = CFAbsoluteTimeGetCurrent()
    let pipelineState: MTLComputePipelineState
    do {
      guard let kernelFunction =
        Renderer.library.makeFunction(name: "convert_mesh") else {
          fatalError("Failed to create kernel function")
        }
      pipelineState = try
        Renderer.device.makeComputePipelineState(
          function: kernelFunction)
    } catch {
      fatalError(error.localizedDescription)
    }
    computeEncoder.setComputePipelineState(pipelineState)

    let totalBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<Int>.stride,
      options: [])
    let vertexTotal = totalBuffer?.contents().bindMemory(to: Int.self, capacity: 1)
    vertexTotal?.pointee = 0
    computeEncoder.setBuffer(totalBuffer, offset: 0, index: 1)

    for mesh in meshes {
      let vertexBuffer = mesh.vertexBuffers[VertexBuffer.index]
      computeEncoder.setBuffer(vertexBuffer, offset: 0, index: 0)
      let vertexCount = vertexBuffer.length /
        MemoryLayout<VertexLayout>.stride
      let threadsPerGroup = MTLSize(
        width: pipelineState.threadExecutionWidth,
        height: 1,
        depth: 1)
      let threadsPerGrid = MTLSize(width: vertexCount, height: 1, depth: 1)
      computeEncoder.dispatchThreads(
        threadsPerGrid,
        threadsPerThreadgroup: threadsPerGroup)
      computeEncoder.endEncoding()
    }
    commandBuffer.addCompletedHandler { _ in
      print(
        "GPU conversion time:",
        CFAbsoluteTimeGetCurrent() - startTime)
      print("Total Vertices:", vertexTotal?.pointee ?? -1)
    }
    commandBuffer.commit()
  }
}

extension Model {
  func setTexture(name: String, type: TextureIndices) {
    if let texture = TextureController.loadTexture(name: name) {
      switch type {
      case BaseColor:
        meshes[0].submeshes[0].textures.baseColor = texture
      default: break
      }
    }
  }
}
// swiftlint:enable force_try
