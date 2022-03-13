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

import MetalKit

extension MTLVertexDescriptor {
  static var defaultLayout: MTLVertexDescriptor? {
    MTKMetalVertexDescriptorFromModelIO(.defaultLayout)
  }
}

extension MDLVertexDescriptor {
  static var defaultLayout: MDLVertexDescriptor = {
    let vertexDescriptor = MDLVertexDescriptor()

    // Position and Normal
    var offset = 0
    vertexDescriptor.attributes[Position.index]
      = MDLVertexAttribute(
        name: MDLVertexAttributePosition,
        format: .float3,
        offset: 0,
        bufferIndex: VertexBuffer.index)
    offset += MemoryLayout<float3>.stride
    vertexDescriptor.attributes[Normal.index] =
      MDLVertexAttribute(
        name: MDLVertexAttributeNormal,
        format: .float3,
        offset: offset,
        bufferIndex: VertexBuffer.index)
    offset += MemoryLayout<float3>.stride
    vertexDescriptor.layouts[VertexBuffer.index]
      = MDLVertexBufferLayout(stride: offset)

    // UVs
    vertexDescriptor.attributes[UV.index] =
      MDLVertexAttribute(
        name: MDLVertexAttributeTextureCoordinate,
        format: .float2,
        offset: 0,
        bufferIndex: UVBuffer.index)
    vertexDescriptor.layouts[UVBuffer.index]
      = MDLVertexBufferLayout(stride: MemoryLayout<float2>.stride)

    // Vertex Color
    vertexDescriptor.attributes[Color.index] =
      MDLVertexAttribute(
        name: MDLVertexAttributeColor,
        format: .float3,
        offset: 0,
        bufferIndex: ColorBuffer.index)
    vertexDescriptor.layouts[ColorBuffer.index]
      = MDLVertexBufferLayout(stride: MemoryLayout<float3>.stride)

    vertexDescriptor.attributes[Tangent.index] =
      MDLVertexAttribute(
        name: MDLVertexAttributeTangent,
        format: .float3,
        offset: 0,
        bufferIndex: TangentBuffer.index)
    vertexDescriptor.layouts[TangentBuffer.index]
      = MDLVertexBufferLayout(stride: MemoryLayout<float3>.stride)
    vertexDescriptor.attributes[Bitangent.index] =
      MDLVertexAttribute(
        name: MDLVertexAttributeBitangent,
        format: .float3,
        offset: 0,
        bufferIndex: BitangentBuffer.index)
    vertexDescriptor.layouts[BitangentBuffer.index]
      = MDLVertexBufferLayout(stride: MemoryLayout<float3>.stride)
    return vertexDescriptor
  }()
}

extension Attributes {
  var index: Int {
    return Int(rawValue)
  }
}

extension BufferIndices {
  var index: Int {
    return Int(rawValue)
  }
}

extension TextureIndices {
  var index: Int {
    return Int(rawValue)
  }
}

extension RenderTargetIndices {
  var index: Int {
    return Int(rawValue)
  }
}
