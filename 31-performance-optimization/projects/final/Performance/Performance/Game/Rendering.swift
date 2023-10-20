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

// Rendering
extension Model {
  func render(
    encoder: MTLRenderCommandEncoder,
    uniformsBuffer: MTLBuffer,
    params fragment: Params,
    renderState: RenderState = .mainPass
  ) {
    encoder.pushDebugGroup(name)
    if let pipelineState {
      let pipelineState = renderState == .mainPass ?
        pipelineState : shadowPipelineState
      if let pipelineState {
        encoder.setRenderPipelineState(pipelineState)
      }
    }

    // make the structures mutable
    var params = fragment
    params.tiling = tiling

    encoder.setFragmentBytes(
      &params,
      length: MemoryLayout<Params>.stride,
      index: ParamsBuffer.index)

    for mesh in meshes {
      setVertexBuffers(encoder: encoder, uniformsBuffer: uniformsBuffer, mesh: mesh)

      for submesh in mesh.submeshes {
        if submesh.transparency != params.transparency { continue }

        if renderState != .shadowPass {
          encoder.setFragmentBuffer(
            submesh.materialsBuffer,
            offset: 0,
            index: MaterialBuffer.index)
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

  func setVertexBuffers(
    encoder: MTLRenderCommandEncoder,
    uniformsBuffer: MTLBuffer,
    mesh: Mesh) {
    if let paletteBuffer = mesh.skin?.jointMatrixPaletteBuffer {
      encoder.setVertexBuffer(
        paletteBuffer,
        offset: 0,
        index: JointBuffer.index)
    }
    let currentLocalTransform =
      mesh.transform?.currentTransform ?? .identity
    let index = Renderer.currentFrameIndex
    let pointer = modelTransformBuffers[index]
        .contents().bindMemory(to: ModelTransform.self, capacity: 1)
    pointer.pointee.modelMatrix =
      transform.modelMatrix * currentLocalTransform
    pointer.pointee.normalMatrix = pointer.pointee.modelMatrix.upperLeft
    encoder.setVertexBuffer(
      modelTransformBuffers[index],
      offset: 0, index: ModelTransformBuffer.index)

    for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
      encoder.setVertexBuffer(
        vertexBuffer,
        offset: 0,
        index: index)
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
}
