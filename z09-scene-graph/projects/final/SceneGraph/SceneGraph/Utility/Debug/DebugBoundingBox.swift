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

class DebugBoundingBox {
  let pipelineState: MTLRenderPipelineState
  let boundingBox: MDLAxisAlignedBoundingBox
  let boundingBoxMeshBuffer: MTLBuffer
  let boundingBoxIndexBuffer: MTLBuffer
  let boundingBoxIndexCount: Int
  let vertices: [Float]

  init(boundingBox: MDLAxisAlignedBoundingBox) {
    self.boundingBox = boundingBox
    let library = Renderer.device.makeDefaultLibrary()
    let vertexFunction = library?.makeFunction(name: "debug_vertex")
    let fragmentFunction = library?.makeFunction(name: "debug_fragment")
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.colorPixelFormat
    
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    do {
      pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
    vertices = DebugBoundingBox.createMeshFromBoundingBox(boundingBox: boundingBox)
    
    self.boundingBoxMeshBuffer = Renderer.device.makeBuffer(bytes: vertices,
                          length: vertices.count * MemoryLayout<Float>.size, options: [])!
    self.boundingBoxIndexBuffer = Renderer.device.makeBuffer(bytes: indices,
                          length: indices.count * MemoryLayout<UInt16>.size, options: [])!
    self.boundingBoxIndexCount = indices.count
  }
  
  func render(renderEncoder: MTLRenderCommandEncoder, uniforms: Uniforms) {
    var uniforms = uniforms
    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.setVertexBuffer(boundingBoxMeshBuffer, offset: 0, index: 21)
    renderEncoder.setVertexBytes(&uniforms,
                                 length: MemoryLayout<Uniforms>.stride,
                                 index: Int(BufferIndexUniforms.rawValue))
    renderEncoder.drawIndexedPrimitives(type: .line, indexCount: boundingBoxIndexCount,
                                        indexType: .uint16, indexBuffer: boundingBoxIndexBuffer,
                                        indexBufferOffset: 0)
  }
  
  private static func createMeshFromBoundingBox(boundingBox: MDLAxisAlignedBoundingBox) -> [Float] {
    let maxx = boundingBox.maxBounds.x
    let maxy = boundingBox.maxBounds.y
    let maxz = boundingBox.maxBounds.z
    let minx = boundingBox.minBounds.x
    let miny = boundingBox.minBounds.y
    let minz = boundingBox.minBounds.z
    
    var vertices = [Float]()
    vertices.append(minx)
    vertices.append(miny)
    vertices.append(minz)
    vertices.append(maxx)
    vertices.append(miny)
    vertices.append(minz)
    vertices.append(maxx)
    vertices.append(maxy)
    vertices.append(minz)
    vertices.append(minx)
    vertices.append(maxy)
    vertices.append(minz)
    
    vertices.append(minx)
    vertices.append(miny)
    vertices.append(maxz)
    vertices.append(maxx)
    vertices.append(miny)
    vertices.append(maxz)
    vertices.append(maxx)
    vertices.append(maxy)
    vertices.append(maxz)
    vertices.append(minx)
    vertices.append(maxy)
    vertices.append(maxz)
    return vertices
  }
  
  let indices: [UInt16] = [
    // front
    0, 1, 2,
    2, 3, 0,
    // top
    1, 5, 6,
    6, 2, 1,
    // back
    7, 6, 5,
    5, 4, 7,
    // bottom
    4, 0, 3,
    3, 7, 4,
    // left
    4, 5, 1,
    1, 0, 4,
    // right
    3, 2, 6,
    6, 7, 3,
    ]
}
