///// Copyright (c) 2025 Kodeco Inc.
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

// swiftlint:disable comma
// swiftlint:disable force_unwrapping

import MetalKit

struct Quad {
  let vertices: [float3] = [
    float3(-0.5,  -0.5, 0.0),   // Top-left
    float3(-0.5, 0.5, 0.0),  // Bottom-left
    float3(0.5, 0.5, 0.0),  // Bottom-right
    float3(0.5,  -0.5, 0.0)  // Top-right
  ]
  let uvs: [float2] = [
    float2(0.0, 0.0),     // Top-left
    float2(0.0, 1.0),     // Bottom-left
    float2(1.0, 1.0),     // Bottom-right
    float2(1.0, 0.0)      // Top-right
  ]
  // clockwise
  let indices: [UInt16] = [1, 0, 2, 0, 3, 2]
  var vertexBuffer: MTLBuffer
  var indexBuffer: MTLBuffer
  var uvBuffer: MTLBuffer

  init(device: MTLDevice) {
    vertexBuffer = device.makeBuffer(
      bytes: vertices,
      length: vertices.count * MemoryLayout<float3>.stride,
      options: [])!
    uvBuffer = device.makeBuffer(
      bytes: uvs,
      length: uvs.count * MemoryLayout<float2>.stride,
      options: [])!
    indexBuffer = device.makeBuffer(
      bytes: indices,
      length: indices.count * MemoryLayout<UInt16>.stride,
      options: [])!
  }
}

// swiftlint:enable comma
// swiftlint:enable force_unwrapping
