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

class Grass: Model {
  var tileTransforms: [float4x4] = []
  var transforms: [float4x4] = []
  var transformsBuffer: MTLBuffer
  var tileSize: Float = 10

  let lodRings = [2, 2, 2]
  
  var worldTileSize: Float = 13
  
  init(density: Float) {
    transforms = Self.getTransforms(width: tileSize, height: tileSize, density: density)
    guard let transformsBuffer = Renderer.device.makeBuffer(
      bytes: &transforms,
      length: MemoryLayout<float4x4>.stride * transforms.count)
    else { fatalError("Failed to create grass buffer") }
    self.transformsBuffer = transformsBuffer
    let vertexDescriptor = MDLVertexDescriptor.grassLayout
    super.init(name: "grassLOD0.usdz", vertexDescriptor: vertexDescriptor)
  }

  /// Input camera position x and z and get position in world tile.
  func getTilePosition(row: Int, column: Int) -> float2 {
    let tileX = column - Int(worldTileSize / 2)
    let tileZ = row - Int(worldTileSize / 2)
    let worldX = Float(tileX) * tileSize
    let worldZ = Float(tileZ) * tileSize
    return float2(worldX, worldZ)
  }

  static func getTransforms(width: Float, height: Float, density: Float) -> [float4x4] {
    var transforms: [float4x4] = []
    let spacing = 1.0 / density
    let columns = Int(width * density)
    let rows = Int(height * density)
    for row in 0..<rows {
      for column in 0..<columns {
        let x = Float(column) * spacing - (width / 2)
        let z = Float(row) * spacing - (height / 2)
        let rotation = Float.random(in: 0..<(2 * Float.pi))
        let scale = Float.random(in: 0.4...2) * 5
        let matrix = matrix_float4x4(translation: [x, 0, z])
          * float4x4(scaling: scale)
          * float4x4(rotation: [0, rotation, 0])
        transforms.append(matrix)
      }
    }
    return transforms
  }
  
  
}
