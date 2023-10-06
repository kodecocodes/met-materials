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

struct GameScene {
  lazy var cottage: Model = {
    Model(name: "house.usdz")
  }()

  var models: [Model] = []
  var camera = PlayerCamera()
  var defaultView: Transform {
    Transform(
      position: [1.32, 2.96, 35.38],
      rotation: [-0.16, 3.09, 0])
  }
  var lighting = SceneLighting()
  let skybox: Skybox?
  var terrain: Terrain?

  init() {
    skybox = Skybox(textureName: "sky")
    terrain = Terrain(name: "terrain.usdz")
    terrain?.tiling = 30
    terrain?.position.y = 3

    camera.transform = defaultView
    camera.far = 50

    cottage.position = [0, 0.4, 10]
    cottage.rotation.y = 0.2
    models = [cottage]
  }

  mutating func update(size: CGSize) {
    camera.update(size: size)
  }

  mutating func update(deltaTime: Float) {
    let input = InputController.shared
    if input.keysPressed.contains(.one) {
      camera.transform = Transform()
      camera.transform.rotation.x = -.pi / 2
      camera.transform.position = [4, 30, 22]
      input.keysPressed.remove(.one)
    }
    if input.keysPressed.contains(.two) {
      camera.transform = defaultView
      input.keysPressed.remove(.two)
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
