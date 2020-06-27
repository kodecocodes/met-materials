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
import CoreGraphics

class GameScene: Scene {
  let ground = Model(name: "ground.obj")
  let car = Model(name: "racing-car.obj")
  let orthoCamera = OrthographicCamera()
  var oilcanCount: Int = 25
  let bounds: Float = 100
  var hud: HudNode!
  
  override func setupScene() {
    skybox = Skybox(textureName: "sky")
    
    hud = HudNode(name: "Hud", size: sceneSize)
    add(node: hud, render: false)
    
    var bodies: [Node] = []
    
    for _ in 0..<oilcanCount {
      let o = Model(name: "oilcan.obj")
      add(node: o)
      o.position.x = .random(in: -bounds..<bounds)
      o.position.z = .random(in: -bounds..<bounds)
      o.scale = [3, 3, 3]
      bodies.append(o)
    }


    let instanceCount = 100
    let tree = Model(name: "treefir.obj", instanceCount: instanceCount)
    add(node: tree)
    for i in 0..<instanceCount {
      var transform = Transform()
      transform.position.x = .random(in: -bounds..<bounds)
      transform.position.z = .random(in: -bounds..<bounds)
      transform.scale = [2, 2, 2]
      tree.updateBuffer(instance: i, transform: transform)
      let node = Node()
      node.position = transform.position
      node.boundingBox = tree.boundingBox
      add(node: node, render: false)
      bodies.append(node)
    }

    inputController.keyboardDelegate = self
    ground.scale = [10,10,10]
    ground.tiling = 32
    add(node: ground)
    
    camera.position = [0, 1.2, -4]
    add(node: car, parent: camera)
    car.position = [0.35, -1, 0.1]
    
    inputController.translationSpeed = 10.0
    inputController.player = camera
    
    orthoCamera.position = [0, 2, 0]
    orthoCamera.rotation.x = .pi / 2
    cameras.append(orthoCamera)
    
    physicsController.dynamicBody = car
    for body in bodies {
      physicsController.addStaticBody(node: body)
    }
    physicsController.holdAllCollided = true
  }
  
  override func sceneSizeWillChange(to size: CGSize) {
    super.sceneSizeWillChange(to: size)
    let cameraSize: Float = 100
    let ratio = Float(sceneSize.width / sceneSize.height)
    let rect = Rectangle(left: -cameraSize * ratio,
                         right: cameraSize * ratio,
                         top: cameraSize, bottom: -cameraSize)
    orthoCamera.rect = rect
    hud.sceneSizeWillChange(to: size)
  }
  
  override func updateCollidedPlayer() -> Bool {
    for body in physicsController.collidedBodies {
      if body.name == "oilcan.obj" {
        remove(node: body)
        physicsController.removeBody(node: body)
        oilcanCount -= 1
        if oilcanCount <= 0 {
          print("ALL OILCANS FOUND!")
        } else {
          print("Oilcans remaining: ", oilcanCount)
        }
        return true
      }
    }
    return false
  }
}

#if os(macOS)
extension GameScene: KeyboardDelegate {
  func keyPressed(key: KeyboardControl, state: InputState) -> Bool {
    switch key {
    case .key0:
      currentCameraIndex = 0
    case .key1:
      currentCameraIndex = 1
    default:
      break
    }
    return true
  }
}
#endif
