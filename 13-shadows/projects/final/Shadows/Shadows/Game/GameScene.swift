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

  lazy var sun: Model = {
    var sun = Model(name: "sun", primitiveType: .sphere)
    sun.scale = 0.2
    sun.rotation.z = Float(270).degreesToRadians
    sun.meshes[0].submeshes[0].material.baseColor = [0.9, 0.9, 0.9]
    return sun
  }()

  var models: [Model] = []
  var camera = ArcballCamera()

  var defaultView: Transform {
    Transform(
      position: [3.2, 3.1, 1.0],
      rotation: [-0.6, 10.7, 0.0])
  }

  var lighting = SceneLighting()

  var debugMainCamera: ArcballCamera?
  var debugShadowCamera: OrthographicCamera?

  var shouldDrawMainCamera = false
  var shouldDrawLightCamera = false
  var shouldDrawBoundingSphere = false

  var isPaused = false

  init() {
    camera.far = 10
    camera.transform = defaultView
    camera.target = [0, 1, 0]
    camera.distance = 4
    treefir1.position = [-1, 0, 2.5]
    treefir2.position = [-3, 0, -2]
    treefir3.position = [1.5, 0, -0.5]
    models = [treefir1, treefir2, treefir3, train, ground]
  }

  mutating func update(size: CGSize) {
    camera.update(size: size)
  }

  mutating func update(deltaTime: Float) {
    updateInput()
    camera.update(deltaTime: deltaTime)
    if isPaused { return }
    // rotate light around scene
    let rotationMatrix = float4x4(rotation: [0, deltaTime * 0.4, 0])
    let position = lighting.lights[0].position
    lighting.lights[0].position =
    (rotationMatrix * float4(position.x, position.y, position.z, 1)).xyz
    sun.position = lighting.lights[0].position
  }

  mutating func updateInput() {
    let input = InputController.shared
    if input.keysPressed.contains(.one) ||
        input.keysPressed.contains(.two) {
      camera.distance = 4
      if let mainCamera = debugMainCamera {
        camera = mainCamera
        debugMainCamera = nil
        debugShadowCamera = nil
      }
      shouldDrawMainCamera = false
      shouldDrawLightCamera = false
      shouldDrawBoundingSphere = false
      isPaused = false
    }
    if input.keysPressed.contains(.one) {
      camera.transform = Transform()
    }
    if input.keysPressed.contains(.two) {
      camera.transform = defaultView
    }
    if input.keysPressed.contains(.three) {
      shouldDrawMainCamera.toggle()
    }
    if input.keysPressed.contains(.four) {
      shouldDrawLightCamera.toggle()
    }
    if input.keysPressed.contains(.five) {
      shouldDrawBoundingSphere.toggle()
    }
    if !isPaused {
      if shouldDrawMainCamera || shouldDrawLightCamera || shouldDrawBoundingSphere {
        isPaused = true
        debugMainCamera = camera
        debugShadowCamera = OrthographicCamera()
        debugShadowCamera?.viewSize = 16
        debugShadowCamera?.far = 16
        let sun = lighting.lights[0]
        debugShadowCamera?.position = sun.position
        camera.distance = 40
        camera.far = 50
        camera.fov = 120
      }
    }
    input.keysPressed.removeAll()
  }
}
