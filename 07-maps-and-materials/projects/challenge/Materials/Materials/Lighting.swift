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

struct Lighting {
  // Lights
  let sunlight: Light = {
    var light = Lighting.buildDefaultLight()
    light.position = [0.4, 1, -2]
    return light
  }()
  let ambientLight: Light = {
    var light = Lighting.buildDefaultLight()
    light.color = [1, 1, 1]
    light.intensity = 0.1
    light.type = Ambientlight
    return light
  }()
  let fillLight: Light = {
    var light = Lighting.buildDefaultLight()
    light.position = [0, -0.1, 0.4]
    light.specularColor = [0, 0, 0]
    light.color = [0.4, 0.4, 0.4]
    return light
  }()
  
  let lights: [Light]
  let count: UInt32
  
  init() {
    lights = [sunlight, ambientLight, fillLight]
    count = UInt32(lights.count)
  }
  
  static func buildDefaultLight() -> Light {
    var light = Light()
    light.position = [0, 0, 0]
    light.color = [1, 1, 1]
    light.specularColor = [1, 1, 1]
    light.intensity = 0.6
    light.attenuation = float3(1, 0, 0)
    light.type = Sunlight
    return light
  }
}
