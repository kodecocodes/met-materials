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

// Render bounding boxes
let debugRenderBoundingBox = true
class PhysicsController {
  
  var dynamicBody: Node?
  var staticBodies: [Node] = []
  var holdAllCollided = false
  var collidedBodies: [Node] = []
  
  func addStaticBody(node: Node) {
    removeBody(node: node)
    staticBodies.append(node)
  }
  
  func removeBody(node: Node) {
    if let index = staticBodies.firstIndex(where: {
      $0.self === node
    }) {
      staticBodies.remove(at: index)
    }
  }
  
  func checkCollisions() -> Bool {
    collidedBodies = []
    guard let node = dynamicBody else { return false }
    let nodeRadius = max((node.size.x / 2), (node.size.z / 2))
    let nodePosition = node.worldTransform.columns.3.xyz
    for body in staticBodies  {
      let bodyRadius = max((body.size.x / 2), (body.size.z / 2))
      let bodyPosition = body.worldTransform.columns.3.xyz
      let d = distance(nodePosition, bodyPosition)
      if d < (nodeRadius + bodyRadius) {
        // There's a hit
        if holdAllCollided {
          collidedBodies.append(body)
        } else {
          return true
        }
      }
    }
    return collidedBodies.count != 0
  }
}
