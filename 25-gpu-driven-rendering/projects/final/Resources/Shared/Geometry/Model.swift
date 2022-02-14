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

// swiftlint:disable force_try

import MetalKit

class Model: Transformable {
  var transform = Transform()
  var meshes: [Mesh]
  var tiling: UInt32 = 1
  var name: String
  let hasTransparency: Bool
  var boundingBox = MDLAxisAlignedBoundingBox()
  var size: float3 {
    return boundingBox.maxBounds - boundingBox.minBounds
  }
  var currentTime: Float = 0
  let animations: [String: AnimationClip]

  init(name: String) {
    guard let assetURL = Bundle.main.url(
      forResource: name,
      withExtension: nil) else {
      fatalError("Model: \(name) not found")
    }
    let allocator = MTKMeshBufferAllocator(device: Renderer.device)
    let meshDescriptor = MDLVertexDescriptor.defaultLayout
    let asset = MDLAsset(
      url: assetURL,
      vertexDescriptor: meshDescriptor,
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
      Mesh(
        mdlMesh: $0.0,
        mtkMesh: $0.1,
        startTime: asset.startTime,
        endTime: asset.endTime)
    }
    self.name = name
    hasTransparency = meshes.contains { mesh in
      mesh.submeshes.contains { $0.transparency }
    }
    boundingBox = asset.boundingBox
    // animations
    let assetAnimations = asset.animations.objects.compactMap {
      $0 as? MDLPackedJointAnimation
    }
    let animations
      = Dictionary(uniqueKeysWithValues: assetAnimations.map {
      ($0.name, AnimationComponent.load(animation: $0))
      })
    self.animations = animations
  }

  func update(deltaTime: Float) {
    currentTime += deltaTime
    for i in 0..<meshes.count {
      var mesh = meshes[i]
      if let animationClip = animations.first?.value {
        mesh.skeleton?.updatePose(
          animationClip: animationClip,
          at: currentTime)
      }
      mesh.transform?.getCurrentTransform(at: currentTime)
      meshes[i] = mesh
    }
  }

  func updateFragmentMaterials(
    encoder: MTLRenderCommandEncoder,
    submesh: Submesh
  ) {
    for (index, texture) in submesh.allTextures.enumerated() {
      encoder.setFragmentTexture(texture, index: index)
    }
    var material = submesh.material
    encoder.setFragmentBytes(
      &material,
      length: MemoryLayout<Material>.stride,
      index: MaterialBuffer.index)
  }

  func render(
    encoder: MTLRenderCommandEncoder,
    uniforms vertex: Uniforms,
    params fragment: Params,
    renderState: RenderState = .mainPass
  ) {
    encoder.pushDebugGroup(name)
    var uniforms = vertex
    var params = fragment
    params.tiling = tiling


    encoder.setFragmentBytes(
      &params,
      length: MemoryLayout<Params>.stride,
      index: ParamsBuffer.index)

    for mesh in meshes {
      let pipelineState = renderState == .mainPass ?
      mesh.pipelineState : mesh.shadowPipelineState
      encoder.setRenderPipelineState(pipelineState)
      if let paletteBuffer = mesh.skeleton?.jointMatrixPaletteBuffer {
        encoder.setVertexBuffer(
          paletteBuffer,
          offset: 0,
          index: JointBuffer.index)
      }
      let currentLocalTransform =
        mesh.transform?.currentTransform ?? .identity
      uniforms.modelMatrix =
        transform.modelMatrix * currentLocalTransform
      uniforms.normalMatrix = uniforms.modelMatrix.upperLeft
      encoder.setVertexBytes(
        &uniforms,
        length: MemoryLayout<Uniforms>.stride,
        index: UniformsBuffer.index)
      for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
        encoder.setVertexBuffer(
          vertexBuffer,
          offset: 0,
          index: index)
      }

      for submesh in mesh.submeshes {
        if submesh.transparency != params.transparency { continue }

        if renderState != .shadowPass {
          encoder.setFragmentBuffer(
            submesh.argumentBuffer,
            offset: 0,
            index: MaterialBuffer.index)
          if let argumentBuffer = submesh.argumentBuffer {
            encoder.useResource(argumentBuffer, usage: .read)
          }
        }

        encoder.drawIndexedPrimitives(
          type: .triangle,
          indexCount: submesh.indexCount,
          indexType: submesh.indexType,
          indexBuffer: submesh.indexBuffer,
          indexBufferOffset: submesh.indexBufferOffset
        )
      }
    }
    encoder.popDebugGroup()
  }
}
