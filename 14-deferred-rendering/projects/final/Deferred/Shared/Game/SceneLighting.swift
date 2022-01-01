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

// swiftlint:disable force_unwrapping

import MetalKit

struct SceneLighting {
  static func buildDefaultLight() -> Light {
    var light = Light()
    light.position = [0, 0, 0]
    light.color = float3(repeating: 1.0)
    light.specularColor = float3(repeating: 0.6)
    light.attenuation = [1, 0, 0]
    light.type = Sun
    return light
  }

  let sunlight: Light = {
    var light = Self.buildDefaultLight()
    light.position = [3, 3, -2]
    light.color = float3(repeating: 1)
    return light
  }()

  let ambientLight: Light = {
    var light = Self.buildDefaultLight()
    light.color = float3(repeating: 0.1)
    light.type = Ambient
    return light
  }()

  var lights: [Light] = []
  var sunlights: [Light]
  var pointLights: [Light]
  var lightsBuffer: MTLBuffer
  var sunBuffer: MTLBuffer
  var pointBuffer: MTLBuffer

  init() {
    sunlights = [sunlight, ambientLight]
    sunBuffer = Self.createBuffer(lights: sunlights)
    lights = sunlights
    pointLights = Self.createPointLights(
      count: 200,
      min: [-6, 0.1, -6],
      max: [6, 0.3, 6])
    pointBuffer = Self.createBuffer(lights: pointLights)
    lights += pointLights
    lightsBuffer = Self.createBuffer(lights: lights)
  }

  static func createBuffer(lights: [Light]) -> MTLBuffer {
    var lights = lights
    return Renderer.device.makeBuffer(
      bytes: &lights,
      length: MemoryLayout<Light>.stride * lights.count,
      options: [])!
  }

  static func createPointLights(count: Int, min: float3, max: float3) -> [Light] {
    let colors: [float3] = [
      float3(1, 0, 0),
      float3(1, 1, 0),
      float3(1, 1, 1),
      float3(0, 1, 0),
      float3(0, 1, 1),
      float3(0, 0, 1),
      float3(0, 1, 1),
      float3(1, 0, 1)
    ]
    var lights: [Light] = []
    for _ in 0..<count {
      var light = Self.buildDefaultLight()
      light.type = Point
      let x = Float.random(in: min.x...max.x)
      let y = Float.random(in: min.y...max.y)
      let z = Float.random(in: min.z...max.z)
      light.position = [x, y, z]
      light.color = colors[Int.random(in: 0..<colors.count)]
      light.attenuation = [0.2, 10, 50]
      lights.append(light)
    }
    return lights
  }
}
