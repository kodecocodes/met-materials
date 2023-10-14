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

class Skeleton {
  let parentIndices: [Int?]
  let jointPaths: [String]
  let bindTransforms: [float4x4]
  let restTransforms: [float4x4]
  var currentPose: [float4x4] = []

  init?(mdlSkeleton: MDLSkeleton?) {
    guard let mdlSkeleton, !mdlSkeleton.jointPaths.isEmpty else { return nil }
    jointPaths = mdlSkeleton.jointPaths
    parentIndices = Skeleton.getParentIndices(jointPaths: jointPaths)
    bindTransforms = mdlSkeleton.jointBindTransforms.float4x4Array
    restTransforms = mdlSkeleton.jointRestTransforms.float4x4Array
  }

  static func getParentIndices(jointPaths: [String]) -> [Int?] {
    var parentIndices = [Int?](repeating: nil, count: jointPaths.count)
    for (jointIndex, jointPath) in jointPaths.enumerated() {
      let url = URL(fileURLWithPath: jointPath)
      let parentPath = url.deletingLastPathComponent().relativePath
      parentIndices[jointIndex] = jointPaths.firstIndex {
        $0 == parentPath
      }
    }
    return parentIndices
  }

  func mapJoints(from jointPaths: [String]) -> [Int] {
    jointPaths.compactMap { jointPath in
      self.jointPaths.firstIndex(of: jointPath)
    }
  }

  func updatePose(
    at currentTime: Float,
    animationClip: AnimationClip) {
    let time = fmod(currentTime, animationClip.duration)

    // set animation - localPose
    var localPose = [float4x4](
      repeating: .identity,
      count: jointPaths.count)
    for index in 0..<jointPaths.count {
      let pose = animationClip.getPose(
        at: time * animationClip.speed,
        jointPath: jointPaths[index])
      ?? restTransforms[index]
      localPose[index] = pose
    }

    // compute world pose
    var worldPose: [float4x4] = []
    for index in 0..<parentIndices.count {
      let parentIndex = parentIndices[index]
      let localMatrix = localPose[index]
      if let parentIndex {
        worldPose.append(worldPose[parentIndex] * localMatrix)
      } else {
        worldPose.append(localMatrix)
      }
    }

    // apply the inverse bind matrix
    for index in 0..<worldPose.count {
      worldPose[index] *= bindTransforms[index].inverse
    }
    currentPose = worldPose
  }
}
