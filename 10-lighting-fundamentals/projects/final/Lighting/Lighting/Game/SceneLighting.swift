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

import Foundation

struct SceneLighting {
  let sunlight: Light = {
    var light = Self.buildDefaultLight()
    light.position = [1, 2, -2]
    return light
  }()

  let ambientLight: Light = {
    var light = Self.buildDefaultLight()
    light.color = [0.05, 0.1, 0]
    light.type = Ambient
    return light
  }()

  let redLight: Light = {
    var light = Self.buildDefaultLight()
    light.type = Point
    light.position = [-0.8, 0.76, -0.18]
    light.color = [1, 0, 0]
    light.attenuation = [0.5, 2, 1]
    return light
  }()

  lazy var spotlight: Light = {
    var light = Self.buildDefaultLight()
    light.type = Spot
    light.position = [-0.64, 0.64, -1.07]
    light.color = [1, 0, 1]
    light.attenuation = [1, 0.5, 0]
    light.coneAngle = Float(40).degreesToRadians
    light.coneDirection = [0.5, -0.7, 1]
    light.coneAttenuation = 8
    return light
  }()

  var lights: [Light] = []

  init() {
    lights.append(sunlight)
    lights.append(ambientLight)
    lights.append(redLight)
    lights.append(spotlight)
  }

  static func buildDefaultLight() -> Light {
    var light = Light()
    light.position = [0, 0, 0]
    light.color = [1, 1, 1]
    light.specularColor = [0.6, 0.6, 0.6]
    light.attenuation = [1, 0, 0]
    light.type = Sun
    return light
  }
}
