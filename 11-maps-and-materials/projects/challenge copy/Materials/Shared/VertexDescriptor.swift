/// Copyright (c) 2021 Razeware LLC
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

extension MTLVertexDescriptor {
  static var defaultLayout: MTLVertexDescriptor? {
    MTKMetalVertexDescriptorFromModelIO(.defaultLayout)
  }
}

extension MDLVertexDescriptor {
  static var defaultLayout: MDLVertexDescriptor = {
    let vertexDescriptor = MDLVertexDescriptor()
    var offset = 0
    vertexDescriptor.attributes[Position.value]
      = MDLVertexAttribute(
        name: MDLVertexAttributePosition,
        format: .float3,
        offset: 0,
        bufferIndex: BufferIndexVertices.value)
    offset += MemoryLayout<float3>.stride
    vertexDescriptor.attributes[Normal.value] =
      MDLVertexAttribute(
        name: MDLVertexAttributeNormal,
        format: .float3,
        offset: offset,
        bufferIndex: BufferIndexVertices.value)
    offset += MemoryLayout<float3>.stride
    vertexDescriptor.layouts[BufferIndexVertices.value]
      = MDLVertexBufferLayout(stride: offset)
    vertexDescriptor.attributes[UV.value] =
      MDLVertexAttribute(
        name: MDLVertexAttributeTextureCoordinate,
        format: .float2,
        offset: 0,
        bufferIndex: BufferIndexUVs.value)
    vertexDescriptor.layouts[BufferIndexUVs.value]
    = MDLVertexBufferLayout(stride: MemoryLayout<float2>.stride)
    vertexDescriptor.attributes[Color.value] =
      MDLVertexAttribute(
        name: MDLVertexAttributeColor,
        format: .float3,
        offset: 0,
        bufferIndex: BufferIndexColors.value)
    vertexDescriptor.layouts[BufferIndexColors.value]
    = MDLVertexBufferLayout(stride: MemoryLayout<float3>.stride)
    vertexDescriptor.attributes[Tangent.value] =
      MDLVertexAttribute(
        name: MDLVertexAttributeTangent,
        format: .float3,
        offset: 0,
        bufferIndex: BufferIndexTangent.value)
    vertexDescriptor.layouts[BufferIndexTangent.value]
      = MDLVertexBufferLayout(stride: MemoryLayout<float3>.stride)
    vertexDescriptor.attributes[Bitangent.value] =
      MDLVertexAttribute(
        name: MDLVertexAttributeBitangent,
        format: .float3,
        offset: 0,
        bufferIndex: BufferIndexBitangent.value)
    vertexDescriptor.layouts[BufferIndexBitangent.value]
      = MDLVertexBufferLayout(stride: MemoryLayout<float3>.stride)
    return vertexDescriptor
  }()
}

extension Attributes {
  var value: Int {
    return Int(self.rawValue)
  }
}

extension BufferIndices {
  var value: Int {
    return Int(self.rawValue)
  }
}

extension TextureIndices {
  var value: Int {
    return Int(self.rawValue)
  }
}
