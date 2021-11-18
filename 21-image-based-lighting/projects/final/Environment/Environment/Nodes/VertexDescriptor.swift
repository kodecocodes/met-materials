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


import ModelIO

extension MDLVertexDescriptor {
  static var defaultVertexDescriptor: MDLVertexDescriptor = {
    let vertexDescriptor = MDLVertexDescriptor()
    
    var offset = 0
    // position attribute
    vertexDescriptor.attributes[Int(Position.rawValue)]
      = MDLVertexAttribute(name: MDLVertexAttributePosition,
                           format: .float3,
                           offset: 0,
                           bufferIndex: Int(BufferIndexVertices.rawValue))
    offset += MemoryLayout<float3>.stride
    
    // normal attribute
    vertexDescriptor.attributes[Int(Normal.rawValue)] =
      MDLVertexAttribute(name: MDLVertexAttributeNormal,
                         format: .float3,
                         offset: offset,
                         bufferIndex: Int(BufferIndexVertices.rawValue))
    offset += MemoryLayout<float3>.stride
    
    // add the uv attribute here
    vertexDescriptor.attributes[Int(UV.rawValue)] =
      MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
                         format: .float2,
                         offset: offset,
                         bufferIndex: Int(BufferIndexVertices.rawValue))
    offset += MemoryLayout<float2>.stride
    
    vertexDescriptor.attributes[Int(Tangent.rawValue)] =
      MDLVertexAttribute(name: MDLVertexAttributeTangent,
                         format: .float3,
                         offset: 0,
                         bufferIndex: 1)
    
    vertexDescriptor.attributes[Int(Bitangent.rawValue)] =
      MDLVertexAttribute(name: MDLVertexAttributeBitangent,
                         format: .float3,
                         offset: 0,
                         bufferIndex: 2)
    
    // color attribute
    vertexDescriptor.attributes[Int(Color.rawValue)] =
      MDLVertexAttribute(name: MDLVertexAttributeColor,
                         format: .float3,
                         offset: offset,
                         bufferIndex: Int(BufferIndexVertices.rawValue))
    
    offset += MemoryLayout<float3>.stride
    
    // joints attribute
    vertexDescriptor.attributes[Int(Joints.rawValue)] =
      MDLVertexAttribute(name: MDLVertexAttributeJointIndices,
                         format: .uShort4,
                         offset: offset,
                         bufferIndex: Int(BufferIndexVertices.rawValue))
    offset += MemoryLayout<ushort>.stride * 4
    
    vertexDescriptor.attributes[Int(Weights.rawValue)] =
      MDLVertexAttribute(name: MDLVertexAttributeJointWeights,
                         format: .float4,
                         offset: offset,
                         bufferIndex: Int(BufferIndexVertices.rawValue))
    offset += MemoryLayout<float4>.stride
     

    vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: offset)
    vertexDescriptor.layouts[1] =
      MDLVertexBufferLayout(stride: MemoryLayout<float3>.stride)
    vertexDescriptor.layouts[2] =
      MDLVertexBufferLayout(stride: MemoryLayout<float3>.stride)
    return vertexDescriptor
    
  }()
}
