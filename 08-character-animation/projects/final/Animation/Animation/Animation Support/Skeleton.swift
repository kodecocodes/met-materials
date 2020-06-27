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

struct Skeleton {
  let parentIndices: [Int?]
  let jointPaths: [String]
  let bindTransforms: [float4x4]
  let restTransforms: [float4x4]
  let jointMatrixPaletteBuffer: MTLBuffer?
  
  static func getParentIndices(jointPaths: [String]) -> [Int?] {
    var parentIndices = [Int?](repeating: nil, count: jointPaths.count)
    for (jointIndex, jointPath) in jointPaths.enumerated() {
      let url = URL(fileURLWithPath: jointPath)
      let parentPath = url.deletingLastPathComponent().relativePath
      parentIndices[jointIndex] = jointPaths.firstIndex { $0 == parentPath }
    }
    return parentIndices
  }
  
  init?(animationBindComponent: MDLAnimationBindComponent?) {
    guard let skeleton = animationBindComponent?.skeleton else {
      return nil
    }
    jointPaths = skeleton.jointPaths
    bindTransforms = skeleton.jointBindTransforms.float4x4Array
    restTransforms = skeleton.jointRestTransforms.float4x4Array
    parentIndices = Skeleton.getParentIndices(jointPaths: jointPaths)
    
    let bufferSize = jointPaths.count * MemoryLayout<float4x4>.stride
    jointMatrixPaletteBuffer =
      Renderer.device.makeBuffer(length: bufferSize,
                                 options: [])
  }
  
  func updatePose(animationClip: AnimationClip,
                  at time: Float) {
    guard
      let paletteBuffer = jointMatrixPaletteBuffer else {
        return
    }
    var palettePointer =
      paletteBuffer.contents().bindMemory(to: float4x4.self,
                                          capacity: jointPaths.count)
    palettePointer.initialize(repeating: .identity(),
                              count: jointPaths.count)
    var poses = [float4x4](repeatElement(.identity(),
                                         count: jointPaths.count))
    for (jointIndex, jointPath) in jointPaths.enumerated() {
      let pose =
        animationClip.getPose(at: time * animationClip.speed,
                              jointPath: jointPath)
          ?? restTransforms[jointIndex]

      let parentPose: float4x4
      if let parentIndex = parentIndices[jointIndex] {
        parentPose = poses[parentIndex]
      } else {
        parentPose = .identity()
      }
      poses[jointIndex] = parentPose * pose
      palettePointer.pointee =
        poses[jointIndex] * bindTransforms[jointIndex].inverse
      palettePointer = palettePointer.advanced(by: 1)
    }
    
  }
}
