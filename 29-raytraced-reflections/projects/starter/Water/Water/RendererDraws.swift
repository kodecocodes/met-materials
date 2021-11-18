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

extension Renderer {

  func renderHouse(renderEncoder: MTLRenderCommandEncoder) {
    renderEncoder.pushDebugGroup("house")
    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.setVertexBuffer(model.vertexBuffers[0].buffer,
                                  offset: 0, index: 0)
    uniforms.modelMatrix = modelTransform.matrix
    uniforms.normalMatrix = modelTransform.matrix.upperLeft()
    renderEncoder.setVertexBytes(&uniforms,
                                 length: MemoryLayout<Uniforms>.stride,
                                 index: Int(BufferIndexUniforms.rawValue))
    renderEncoder.setFragmentTexture(modelTexture, index: 0)
    for submesh in model.submeshes {
      renderEncoder.drawIndexedPrimitives(type: .triangle,
                                          indexCount: submesh.indexCount,
                                          indexType: submesh.indexType,
                                          indexBuffer: submesh.indexBuffer.buffer,
                                          indexBufferOffset: submesh.indexBuffer.offset)
    }
    renderEncoder.popDebugGroup()
  }

  func renderTerrain(renderEncoder: MTLRenderCommandEncoder) {
    renderEncoder.pushDebugGroup("terrain")
    renderEncoder.setCullMode(.none)
    renderEncoder.setRenderPipelineState(terrainPipelineState)

    renderEncoder.setFragmentTexture(terrainTexture, index: 0)
    renderEncoder.setVertexBuffer(terrain.vertexBuffers[0].buffer, offset: 0, index: 0)
    uniforms.modelMatrix = terrainTransform.matrix
    uniforms.normalMatrix = terrainTransform.matrix.upperLeft()
    renderEncoder.setVertexBytes(&uniforms,
                                 length: MemoryLayout<Uniforms>.stride,
                                 index: Int(BufferIndexUniforms.rawValue))
    renderEncoder.setFragmentTexture(underwaterTexture, index: 1)
    for submesh in terrain.submeshes {
      renderEncoder.drawIndexedPrimitives(type: .triangle,
                                          indexCount: submesh.indexCount,
                                          indexType: submesh.indexType,
                                          indexBuffer: submesh.indexBuffer.buffer,
                                          indexBufferOffset: submesh.indexBuffer.offset)
    }
    renderEncoder.popDebugGroup()
  }
  
  func renderSkybox(renderEncoder: MTLRenderCommandEncoder) {
    renderEncoder.pushDebugGroup("skybox")
    renderEncoder.setCullMode(.back)
    renderEncoder.setRenderPipelineState(skyboxPipelineState)
    renderEncoder.setVertexBuffer(skybox.vertexBuffers[0].buffer, offset: 0, index: 0)
    var newMatrix = uniforms.viewMatrix
    newMatrix.columns.3 = [0, 0, 0, 1]
    uniforms.skyboxViewMatrix = newMatrix
    uniforms.modelMatrix = skyboxTransform.matrix
    renderEncoder.setVertexBytes(&uniforms,
                                 length: MemoryLayout<Uniforms>.stride,
                                 index: Int(BufferIndexUniforms.rawValue))

    renderEncoder.setFragmentTexture(skyboxTexture, index: 0)
    let submesh = skybox.submeshes[0]
    renderEncoder.drawIndexedPrimitives(type: .triangle,
                                        indexCount: submesh.indexCount,
                                        indexType: submesh.indexType,
                                        indexBuffer: submesh.indexBuffer.buffer,
                                        indexBufferOffset: 0)
    renderEncoder.popDebugGroup()
  }
}
