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
// swiftlint:disable identifier_name
// swiftlint:disable colon

struct Vertex {
  var x: Float
  var y: Float
  var z: Float
}

struct Triangle {
  var vertices: [Vertex] = [
    Vertex(x: -0.7, y:  0.8, z: 0),
    Vertex(x: -0.7, y: -0.5, z: 0),
    Vertex(x:  0.4, y:  0.1, z: 0)
  ]

  var indices: [UInt16] = [
    0, 1, 2
  ]

  let vertexBuffer: MTLBuffer
  let indexBuffer: MTLBuffer

  init(device: MTLDevice, scale: Float = 1) {
    vertices = vertices.map {
      Vertex(x: $0.x * scale, y: $0.y * scale, z: $0.z * scale)
    }
    guard let vertexBuffer = device.makeBuffer(
      bytes: &vertices,
      length: MemoryLayout<Vertex>.stride * vertices.count,
      options: []) else {
      fatalError("Unable to create vertex buffer")
    }
    self.vertexBuffer = vertexBuffer

    guard let indexBuffer = device.makeBuffer(
      bytes: &indices,
      length: MemoryLayout<UInt16>.stride * indices.count,
      options: []) else {
      fatalError("Unable to create index buffer")
    }
    self.indexBuffer = indexBuffer
  }
}

// swiftlint:enable identifier_name
// swiftlint:enable colon
