///// Copyright (c) 2019 Razeware LLC
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
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import simd

let vertices: [float3] = [
  [-1,  0,  1],
  [ 1,  0, -1],
  [-1,  0, -1],
  [-1,  0,  1],
  [ 1,  0, -1],
  [ 1,  0,  1]
]

let vertexBuffer = Renderer.device.makeBuffer(bytes: vertices,
                                              length: MemoryLayout<float3>.stride * vertices.count,
                                              options: [])

/**
 Create control points
 - Parameters:
     - patches: number of patches across and down
     - size: size of plane
 - Returns: an array of patch control points. Each group of four makes one patch.
**/
func createControlPoints(patches: (horizontal: Int, vertical: Int),
                         size: (width: Float, height: Float)) -> [float3] {
  
  var points: [float3] = []
  // per patch width and height
  let width = 1 / Float(patches.horizontal)
  let height = 1 / Float(patches.vertical)
  
  for j in 0..<patches.vertical {
    let row = Float(j)
    for i in 0..<patches.horizontal {
      let column = Float(i)
      let left = width * column
      let bottom = height * row
      let right = width * column + width
      let top = height * row + height
      
      points.append([left, 0, top])
      points.append([right, 0, top])
      points.append([right, 0, bottom])
      points.append([left, 0, bottom])
    }
  }
  // size and convert to Metal coordinates
  // eg. 6 across would be -3 to + 3
  points = points.map {
    [$0.x * size.width - size.width / 2,
     0,
     $0.z * size.height - size.height / 2]
  }
  return points
}
