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

import MetalKit

extension Renderer {
  func zoomUsing(delta: CGFloat, sensitivity: Float) {
    camera.position.z += Float(delta) * sensitivity
  }
  
  func rotateUsing(translation: float2) {
    let sensitivity: Float = 0.01
    camera.rotation.x += Float(translation.y) * sensitivity
    camera.rotation.y -= Float(translation.x) * sensitivity
  }
  
  func random(range: CountableClosedRange<Int>) -> Int {
    var offset = 0
    if range.lowerBound < 0 {
      offset = abs(range.lowerBound)
    }
    let min = UInt32(range.lowerBound + offset)
    let max = UInt32(range.upperBound + offset)
    return Int(min + arc4random_uniform(max-min)) - offset
  }
  
  func createPointLights(count: Int, min: float3, max: float3) {
    let colors: [float3] = [
      float3(1, 0, 0),
      float3(1, 1, 0),
      float3(1, 1, 1),
      float3(0, 1, 0),
      float3(0, 1, 1),
      float3(0, 0, 1),
      float3(0, 1, 1),
      float3(1, 0, 1) ]
    let newMin: float3 = [min.x*100, min.y*100, min.z*100]
    let newMax: float3 = [max.x*100, max.y*100, max.z*100]
    for _ in 0..<count {
      var light = buildDefaultLight()
      light.type = Pointlight
      let x = Float(random(range: Int(newMin.x)...Int(newMax.x))) * 0.01
      let y = Float(random(range: Int(newMin.y)...Int(newMax.y))) * 0.01
      let z = Float(random(range: Int(newMin.z)...Int(newMax.z))) * 0.01
      light.position = [x, y, z]
      light.color = colors[random(range: 0...colors.count)]
      light.intensity = 0.6
      light.attenuation = float3(1.5, 1, 1)
      lights.append(light)
    }
  }  
}
