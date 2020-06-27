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


import Foundation

class RocksScene: Scene {
  let ground = Model(name: "ground.obj")
  
  override func setupScene() {
    skybox = Skybox(textureName: nil)
    ground.tiling = 16
    add(node: ground)
    
    let instanceCount = 25
    
    let textureNames = ["rock1-color", "rock2-color", "rock3-color"]
    let morphTargetNames = ["rock1", "rock2", "rock3"]
    let rocks = Nature(name: "Rocks", instanceCount: instanceCount,
                       textureNames: textureNames,
                       morphTargetNames: morphTargetNames)
    add(node: rocks)
    for i in 0..<instanceCount {
      var transform = Transform()
      transform.position.x = .random(in: -10..<10)
      transform.position.z = .random(in: 0..<5)
      transform.rotation.y = .random(in: -Float.pi..<Float.pi)
      rocks.updateBuffer(instance: i, transform: transform)
    }
    
    inputController.player = camera
    camera.position.z = -2
    camera.position.y = 1
  }
}
