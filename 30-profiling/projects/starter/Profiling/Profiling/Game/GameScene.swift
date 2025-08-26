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
  lazy var scene: Model = {
    Model(name: "game-scene.usda")
  }()
  lazy var phoenix: Phoenix = {
    let model = Model(name: "phoenix_bird.usdz")
    let phoenix = Phoenix(model: model)
    return phoenix
  }()

  lazy var firePit: Model = {
    Model(name: "fire-pit.usdz")
  }()

  var models: [Model] = []
  var camera = PlayerCamera()
  var defaultView: Transform {
    Transform(
      position: [0.82, 27.94, -53.9],
      rotation: [-0.48, 3.65, 0.0])
  }
  var aerialView: Transform {
    Transform(
      position: [-3.62, 106.02, -2.67],
      rotation: [-1.57, 4.39, 0.0])
  }
  var lighting = SceneLighting()
  let skybox: Skybox?
  var water: Water?
  var nature: [Nature] = []
  var particleEffects: [Emitter] = []

  init() {
    skybox = Skybox(textureName: "sky")
    camera.transform = aerialView
    camera.far = 400
    models = [scene, phoenix.model, firePit]
    water = Water()
    water?.position = [0, 1.5, 0]

    firePit.position = [29.8, 5.33, 46.1]
    models += Rocks.setupRocks()
  }


  mutating func update(size: CGSize) {
    camera.update(size: size)
    let fire = ParticleEffects.createFire(size: size)
    fire.transform.position = firePit.position
    particleEffects = [fire]
  }

  mutating func update(deltaTime: Float) {
    water?.update(deltaTime: deltaTime)
    phoenix.update(deltaTime: deltaTime)
    particleEffects.forEach {
      $0.update(deltaTime: deltaTime)
    }
    for model in models {
      model.update(deltaTime: deltaTime)
    }
    let input = InputController.shared
    if input.keysPressed.contains(.zero) {
      camera.transform = Transform()
      input.keysPressed.remove(.zero)
    }
    // looking down
    if input.keysPressed.contains(.one) {
      camera.transform = aerialView
      input.keysPressed.remove(.one)
    }
    if input.keysPressed.contains(.two) {
      camera.transform = defaultView
      input.keysPressed.remove(.two)
    }
    // rocks
    if input.keysPressed.contains(.keyR) {
      camera.transform = Transform(
        position: [-3.1, 6.195, -0.26],
        rotation: [-0.27, 7.08, 0.0])
      input.keysPressed.remove(.keyR)
    }
    // fire
    if input.keysPressed.contains(.keyF) {
      camera.transform = Transform(
        position: [35.65, 8.43, 43.66],
        rotation: [-0.063, 4.754, 0.0])
      input.keysPressed.remove(.keyF)
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
