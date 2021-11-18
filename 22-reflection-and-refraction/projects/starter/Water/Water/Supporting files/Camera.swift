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

class Camera {
  var aspect: Float = 1
  var fov: Float = Float(60).degreesToRadians

  var projectionMatrix: float4x4 {
    return float4x4(projectionFov: fov,
                    near: Float(near),
                    far: Float(far),
                    aspect: aspect)
  }
  
  init() {}
  
  init(near: Float = Float(near), far: Float = Float(far), aspect: Float, fov: Float = 1.135) {
    self.aspect = aspect
    self.fov = fov
  }
  
  var minY: Float = 0.2

  var viewMatrix = float4x4.identity()
  var transform = Transform() {
    didSet {
      let translateMatrix = float4x4(translation: [-transform.position.x,
                                                   -transform.position.y,
                                                   -transform.position.z])
      let rotateMatrix = float4x4(rotation: transform.rotation)
      viewMatrix =  rotateMatrix * translateMatrix
    }
  }
}
