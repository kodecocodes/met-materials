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
  lazy var train: Model = {
    Model(name: "train.usdz")
  }()
  lazy var treefir1: Model = {
    Model(name: "treefir.usdz")
  }()
  lazy var treefir2: Model = {
    Model(name: "treefir.usdz")
  }()
  lazy var treefir3: Model = {
    Model(name: "treefir.usdz")
  }()

  lazy var ground: Model = {
    var ground = Model(name: "ground", primitiveType: .plane)
    ground.scale = 40
    ground.rotation.z = Float(270).degreesToRadians
    ground.meshes[0].submeshes[0].material.baseColor = [0.9, 0.9, 0.9]
    return ground
  }()

  var models: [Model] = []
  var camera = ArcballCamera()

  var defaultView: Transform {
    Transform(
      position: [3.2, 3.1, 1.0],
      rotation: [-0.6, 10.7, 0.0])
  }

  var lighting = SceneLighting()

  init() {
    camera.far = 10
    camera.transform = defaultView
    camera.target = [0, 1, 0]
    camera.distance = 4
    treefir1.position = [-1, 0, 2.5]
    treefir2.position = [-3, 0, -2]
    treefir3.position = [1.5, 0, -0.5]
    models = [ground, treefir1, treefir2, treefir3, train]
  }

  mutating func update(size: CGSize) {
    camera.update(size: size)
  }

  mutating func update(deltaTime: Float) {
    updateInput()
    camera.update(deltaTime: deltaTime)
  }

  mutating func updateInput() {
    let input = InputController.shared
    if input.keysPressed.contains(.one) ||
        input.keysPressed.contains(.two) {
      camera.distance = 4
    }
    if input.keysPressed.contains(.one) {
      camera.transform = Transform()
    }
    if input.keysPressed.contains(.two) {
      camera.transform = defaultView
    }
    input.keysPressed.removeAll()
  }
}
