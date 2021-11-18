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

class Node {
  var name: String = "untitled"
  var position: float3 = [0, 0, 0]
  var rotation: float3 = [0, 0, 0] {
    didSet {
      let rotationMatrix = float4x4(rotation: rotation)
      quaternion = simd_quatf(rotationMatrix)
    }
  }
  var quaternion = simd_quatf()
  var scale:float3 = [1, 1, 1]

  var modelMatrix: float4x4 {
    let translateMatrix = float4x4(translation: position)
    let rotateMatrix = float4x4(quaternion)
    let scaleMatrix = float4x4(scaling: scale)
    return translateMatrix * rotateMatrix * scaleMatrix
  }
  
  var boundingBox = MDLAxisAlignedBoundingBox()
  var size: float3 {
    return boundingBox.maxBounds - boundingBox.minBounds
  }
  
  var parent: Node?
  var children: [Node] = []
  
  func update(deltaTime: Float) {
    // override this
  }

  final func add(childNode: Node) {
    children.append(childNode)
    childNode.parent = self
  }
  
  final func remove(childNode: Node) {
    for child in childNode.children {
      child.parent = self
      children.append(child)
    }
    childNode.children = []
    guard let index = (children.firstIndex {
      $0 === childNode
    }) else { return }
    children.remove(at: index)
    childNode.parent = nil
  }
  
  var worldTransform: float4x4 {
    if let parent = parent {
      return parent.worldTransform * self.modelMatrix
    }
    return modelMatrix
  }
  
  var forwardVector: float3 {
    return normalize([sin(rotation.y), 0, cos(rotation.y)])
  }
  
  var rightVector: float3 {
    return [forwardVector.z, forwardVector.y, -forwardVector.x]
  }
}

