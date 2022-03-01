/// Copyright (c) 2022 Razeware LLC
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
  let skeletonCount = 10
  lazy var skeletons: [Model] = []
  lazy var skeletonDirections = [Float](repeating: -1, count: skeletonCount)
  lazy var skeletonPositions = [float3](repeating: .zero, count: skeletonCount)
  lazy var bellTower = Model(name: "bell-tower.obj")
  lazy var blacksmith = Model(name: "blacksmith.obj")
  lazy var house1 = Model(name: "house1.obj")
  lazy var pine5 = Model(name: "pine-5.obj")
  lazy var birch3 = Model(name: "birch-3.obj")

  lazy var ground: Model = {
    let model = Model(name: "large_plane.obj")
    model.tiling = 30
    return model
  }()

  var models: [Model] = []
  var nature: [Nature] = []
  var camera = ArcballCamera()
  var defaultDistance: Float = 22
  var defaultView: Transform {
    Transform(
      position: [-0.77, 7.3, 21.8],
      rotation: [-0.06, 3.1, 0])
  }
  var lighting = SceneLighting()
  let skybox: Skybox?

  init() {
    skybox = Skybox(textureName: "sky")
    camera.target = [0, 6, 0]
    camera.distance = defaultDistance
    camera.transform = defaultView
    camera.far = 1000
    ground.scale = 10
    models = [ground, bellTower, blacksmith, house1, pine5, birch3]

    skeletons = (0..<skeletonCount).map { index in
      var skeleton = Model(name: "skeleton.usda")
      skeleton.currentTime = Float.random(in: 0..<2)
      skeleton.scale = 0.01
      skeletonPositions[index].x = Float.random(in: 0...5)
      skeletonPositions[index].z = Float.random(in: 4...12)
      skeleton.position = skeletonPositions[index]
      skeleton.rotation = [-.pi / 2, .pi, -.pi / 2]
      skeleton.animations.first?.value.speed = 1.5
      return skeleton
    }
    models += skeletons

    // buildings
    house1.position.x = -10
    blacksmith.position.x = 10
    blacksmith.rotation.y = .pi / 4
    blacksmith.position.z = 2
    birch3.position = [-5, 0, -7]
    pine5.position = [7, 0, -6]

    var barrels = (0..<4).map { _ in
      Model(name: "barrel.usdz")
    }
    barrels[0].position = [4.8, 0, 4]
    barrels[1].rotation = [0, 2.5, .pi / 2]
    barrels[1].position = [-6, barrels[1].size.x / 2, 2]
    barrels[2].position = [-5.5, 0, 1.5]
    barrels[3].position = [-6.5, 0, 2]
    models += barrels

    nature = [loadRocks(count: 200)]
    var grass = setupGrass(count: 50000, width: 3, depth: 2)
    grass.position.x = 5
    grass.position.z = 8
    grass.scale = 2
    nature += [grass]
  }

  func loadRocks(count: Int) -> Nature {
    // Load Nature
    let textureNames = ["rock1-color", "rock2-color", "rock3-color"]
    let morphTargetNames = ["rock1", "rock2", "rock3"]
    let rocks = Nature(
      name: "Rocks",
      instanceCount: count,
      textureNames: textureNames,
      morphTargetNames: morphTargetNames)
    for i in 0..<count {
      var transform = Transform()
      transform.position.x = .random(in: -15..<(-5))
      transform.position.z = .random(in: 5..<10)
      transform.rotation.y = .random(in: -Float.pi..<Float.pi)
      let textureID = Int.random(in: 0..<textureNames.count)
      let morphTargetID = Int.random(in: 0..<morphTargetNames.count)
      rocks.updateBuffer(
        instance: i,
        transform: transform,
        textureID: textureID,
        morphTargetID: morphTargetID)
    }
    return rocks
  }

  func setupGrass(
    count: Int,
    width: Float,
    depth: Float
  ) -> Nature {
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

    let grass = Nature(
      name: "grass",
      instanceCount: count,
      textureNames: textureNames,
      morphTargetNames: morphNames)
    for i in 0..<count {
      var transform = Transform()
      transform.position.x = .random(in: -width..<width)
      transform.position.z = .random(in: 0..<depth)
      transform.rotation.y = .random(in: -Float.pi..<Float.pi)
      let textureId = Int.random(in: 0..<textureNames.count)
      let morphId = Int.random(in: 0..<morphCount)
      grass.updateBuffer(
        instance: i,
        transform: transform,
        textureID: textureId,
        morphTargetID: morphId)
    }
    return grass
  }


  mutating func update(size: CGSize) {
    camera.update(size: size)
  }


  mutating func update(deltaTime: Float) {
    let maxDistance: Float = 2
    let stride = 0.5 * deltaTime
    for index in skeletons.indices {
      skeletons[index].position.x += stride * skeletonDirections[index]
      let maxDistance = (skeletonPositions[index].x + maxDistance)
      if abs(skeletons[index].position.x) > maxDistance {
        skeletonDirections[index] *= -1
        skeletons[index].rotation.z += .pi
        if skeletons[index].position.x.sign == .minus {
          skeletons[index].position.x = -maxDistance
        } else {
          skeletons[index].position.x = maxDistance
        }
      }
    }
    for model in models {
      model.update(deltaTime: deltaTime)
    }
    let input = InputController.shared
    if input.keysPressed.contains(.one) {
      camera.transform = Transform()
      camera.distance = defaultDistance
      input.keysPressed.remove(.one)
    }
    if input.keysPressed.contains(.two) {
      camera.transform = defaultView
      camera.distance = defaultDistance
      input.keysPressed.remove(.two)
    }
    camera.update(deltaTime: deltaTime)
//    print(camera.position, camera.rotation)
  }
}
