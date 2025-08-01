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

import MetalKit

public class Terrain {
  var name = "Terrain"

  public let vertices: [Float] = [
    -1,  1, 0,
    -1, -1, 0,
     1, -1, 0,
     1, -1, 0,
     1,  1, 0,
    -1,  1, 0
  ]
  public let uvs: [Float] = [
    0, 0,
    0, 1,
    1, 1,
    1, 1,
    1, 0,
    0, 0
  ]

  public var buffer: MTLBuffer
  public var uvBuffer: MTLBuffer
  public var texture: MTLTexture?
  public var pipelineState: MTLRenderPipelineState!
  public var samplerState: MTLSamplerState!
  public weak var device: MTLDevice?

  public var position: float3 = [0, 0, 0]
  public var rotation: float3 = [0, 0, 0]
  public var scale: float3 = [1, 1, 1]

  public var modelMatrix: float4x4 {
    let translateMatrix = float4x4(translation: position)
    let rotateMatrix = float4x4(rotation: rotation)
    let scaleMatrix = float4x4(scaling: scale)
    return translateMatrix * scaleMatrix * rotateMatrix
  }

  public init(device: MTLDevice) {
    self.device = device
    buffer = device.makeBuffer(
      bytes: vertices,
      length: vertices.count * MemoryLayout<Float>.size,
      options: [])!
    uvBuffer = device.makeBuffer(
      bytes: uvs,
      length: uvs.count * MemoryLayout<Float>.size,
      options: [])!
  }
}
