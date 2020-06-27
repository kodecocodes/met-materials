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

class Houses: Node {
  var houses: [Model] = []
  
  override init() {
    
    super.init()
    houses.append(Model(name: "houseGround1.obj",
                        vertexFunctionName: "vertex_house",
                        fragmentFunctionName: "fragment_house"))
  }
  
}

extension Houses: Renderable {
  func render(renderEncoder: MTLRenderCommandEncoder,
              uniforms vertex: Uniforms,
              fragmentUniforms fragment: FragmentUniforms) {
    for house in houses {
      var uniforms = vertex
      var fragmentUniforms = fragment
      uniforms.modelMatrix = modelMatrix * house.modelMatrix
      uniforms.normalMatrix = float3x3(normalFrom4x4: modelMatrix * house.modelMatrix)
      
      renderEncoder.setVertexBuffer(house.instanceBuffer, offset: 0,
                                    index: Int(BufferIndexInstances.rawValue))
      renderEncoder.setFragmentSamplerState(house.samplerState, index: 0)
      renderEncoder.setVertexBytes(&uniforms,
                                   length: MemoryLayout<Uniforms>.stride,
                                   index: Int(BufferIndexUniforms.rawValue))
      renderEncoder.setFragmentBytes(&fragmentUniforms,
                                     length: MemoryLayout<FragmentUniforms>.stride,
                                     index: Int(BufferIndexFragmentUniforms.rawValue))
      
      for (index, vertexBuffer) in house.meshes[0].mtkMesh.vertexBuffers.enumerated() {
        renderEncoder.setVertexBuffer(vertexBuffer.buffer,
                                      offset: 0, index: index)
      }
      
      var tiling = 1
      renderEncoder.setFragmentBytes(&tiling, length: MemoryLayout<UInt32>.stride, index: 22)
      for submesh in house.meshes[0].submeshes {
        renderEncoder.setRenderPipelineState(submesh.pipelineState)
        var material = submesh.material
        renderEncoder.setFragmentBytes(&material,
                                       length: MemoryLayout<Material>.stride,
                                       index: Int(BufferIndexMaterials.rawValue))
        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: submesh.mtkSubmesh.indexCount,
                                            indexType: submesh.mtkSubmesh.indexType,
                                            indexBuffer: submesh.mtkSubmesh.indexBuffer.buffer,
                                            indexBufferOffset: submesh.mtkSubmesh.indexBuffer.offset,
                                            instanceCount:  house.instanceCount)
      }
    }
  }
}
