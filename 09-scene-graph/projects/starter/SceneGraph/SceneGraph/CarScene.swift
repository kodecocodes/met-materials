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

class CarScene: Scene {
  let ground = Model(name: "ground.obj")
  let car = Model(name: "racing-car.obj")
  let orthoCamera = OrthographicCamera()
  
  override func setupScene() {
    var bodies: [Node] = []
    var oilcan = Model(name: "oilcan.obj")
    oilcan.position = [-9, 0, -6]
    add(node: oilcan)
    bodies.append(oilcan)
    oilcan = Model(name: "oilcan.obj")
    oilcan.position = [13, 0, -4]
    add(node: oilcan)
    bodies.append(oilcan)
    var tree = Model(name: "treefir.obj")
    tree.position = [-7, 0, 3]
    add(node: tree)
    bodies.append(tree)
    tree = Model(name: "treefir.obj")
    tree.position = [5, 0, 2]
    add(node: tree)
    bodies.append(tree)
    inputController.keyboardDelegate = self
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
    
  }
  
  override func sceneSizeWillChange(to size: CGSize) {
    super.sceneSizeWillChange(to: size)
    let cameraSize: Float = 10
    let ratio = Float(sceneSize.width / sceneSize.height)
    let rect = Rectangle(left: -cameraSize * ratio,
                         right: cameraSize * ratio,
                         top: cameraSize, bottom: -cameraSize)
    orthoCamera.rect = rect
  }
  
}

extension CarScene: KeyboardDelegate {
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
