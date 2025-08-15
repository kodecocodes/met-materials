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
import GameController

struct GameScene {
  var models: [Model] = []
  lazy var ground: Model = {
    var ground = Model(name: "ground", primitiveType: .plane)
    ground.setTexture(name: "grass", type: BaseColor)
    ground.scale = 40
    ground.tiling = 6
    ground.rotation.z = Float(270).degreesToRadians
    return ground
  }()
  lazy var house: Model = {
    Model(name: "house.usdz")
  }()
  lazy var grass0: Model = {
    var grass = Model(name: "grassLOD0.usdz")
    grass.setTexture(name: "grass01-color", type: BaseColor)
    grass.scale = 20
    return grass
  }()
  
  lazy var grass1: Model = {
    var grass = Model(name: "grassLOD1.usdz")
    grass.setTexture(name: "grass01-color", type: BaseColor)
    grass.scale = 20
    grass.position.x += 1
    return grass
  }()
  
  lazy var grass2: Model = {
    var grass = Model(name: "grassLOD2.usdz")
    grass.setTexture(name: "grass02-color", type: BaseColor)
    grass.setTexture(name: "grass02-opacity", type: OpactityTexture)
    grass.scale = 20
    grass.position.x += 2
    return grass
  }()
  
  lazy var grass0dash1: Model = {
    var grass = Model(name: "grassLOD0.usdz")
    grass.setTexture(name: "grass01-color", type: BaseColor)
    return grass
  }()

  lazy var grass0dash2: Model = {
    var grass = Model(name: "grassLOD0.usdz")
    grass.setTexture(name: "grass01-color", type: BaseColor)
    grass.scale = 20
    return grass
  }()

  lazy var grass0dash3: Model = {
    var grass = Model(name: "grassLOD0.usdz")
    grass.setTexture(name: "grass01-color", type: BaseColor)
    grass.scale = 20
    return grass
  }()

  var camera = PlayerCamera()
  var defaultDistance: Float = 5
  var defaultView: Transform {
//    Transform(
//      position: [4.15, 2.4, -2.4],
//      rotation: [-0.28, 5.23, 0])
    Transform(position: [0, 2, 0])
  }

  init() {
    camera.transform = defaultView
    
//    models = [ground, grass0, grass1, grass2]
    models = [ground, house]
  }

  mutating func update(size: CGSize) {
    camera.update(size: size)
  }

  mutating func update(deltaTime: Float) {
    let input = InputController.shared
    if input.keysPressed.contains(.one) {
      camera.transform = Transform()
    }
    if input.keysPressed.contains(.two) {
      camera.transform = defaultView
    }
    let positionYDelta = (input.mouseScroll.x + input.mouseScroll.y)
      * Settings.mouseScrollSensitivity
    let minY: Float = -1
    if camera.position.y + positionYDelta > minY {
      camera.position.y += positionYDelta
    }
    input.mouseScroll = .zero

    camera.update(deltaTime: deltaTime)
  }
}
