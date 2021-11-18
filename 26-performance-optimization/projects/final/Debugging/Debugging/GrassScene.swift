//
/**
 * Copyright (c) 2018 Razeware LLC
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

class GrassScene: Scene {
  let ground = Model(name: "ground.obj")
  let grassSize: Float = 5
  
  override func setupScene() {
    skybox = Skybox(textureName: nil)
    ground.tiling = 16
    add(node: ground)
    
    setupGrass(instanceCount: 50000, width: 10, depth: 10)
    setupTrees(instanceCount: 20)
    setupRocks(instanceCount: 20)
    
    inputController.player = camera
    camera.position.z = -1
    camera.position.y = 1
  }
  
  func setupGrass(instanceCount: Int, width: Float, depth: Float)  {
    let grassCount = 7
    var textureNames: [String] = []
    for i in 1...grassCount {
      textureNames.append("grass" + String(format: "%02d", i))
    }
    let morphCount = 4
    var morphNames: [String] = []
    for i in 1...morphCount {
      morphNames.append("grass" + String(format: "%02d", i))
    }
    
    let grass = Nature(name: "grass", instanceCount: instanceCount,
                       textureNames: textureNames,
                       morphTargetNames: morphNames)
    for i in 0..<instanceCount {
      var transform = Transform()
      transform.position.x = .random(in: -width..<width)
      transform.position.z = .random(in: 0..<depth)
      transform.rotation.y = .random(in: -Float.pi..<Float.pi)
      let textureId = Int.random(in: 0..<textureNames.count)
      let morphId = Int.random(in: 0..<morphCount)
      grass.updateBuffer(instance: i, transform: transform,
                         textureID: textureId, morphTargetID: morphId)
    }
    add(node: grass)
  }

  
  func setupTrees(instanceCount: Int) {
    let tree = Model(name: "tree.obj", instanceCount: instanceCount)
    add(node: tree)
    for i in 0..<instanceCount {
      var transform = Transform()
      transform.position.x = .random(in: -15..<15)
      transform.position.z = .random(in: 10..<15)
      transform.rotation.y = .random(in: -Float.pi..<Float.pi)
      tree.updateBuffer(instance: i, transform: transform)
    }
  }
  
  func setupRocks(instanceCount: Int) {
    let textureNames = ["rock1-color", "rock2-color", "rock3-color"]
    let morphs = ["rock1", "rock2", "rock3"]
    let rocks = Nature(name: "Rocks", instanceCount: instanceCount,
                       textureNames: textureNames,
                       morphTargetNames: morphs)
    add(node: rocks)
    for i in 0..<instanceCount {
      var transform = Transform()
      transform.position.x = .random(in: -10..<10)
      transform.position.z = .random(in: 5..<10)
      transform.rotation.y = .random(in: -Float.pi..<Float.pi)
      let textureId = Int.random(in: 0..<textureNames.count)
      let morphId = Int.random(in: 0..<morphs.count)
      rocks.updateBuffer(instance: i, transform: transform,
                         textureID: textureId, morphTargetID: morphId)
      
    }
  }
}
