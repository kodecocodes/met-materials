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

import Foundation

struct Transform {
  var position: float3 = [0, 0, 0]
  var rotation: float3 = [0, 0, 0] {
    didSet {
      let rotationMatrix = float4x4(rotation: rotation)
      quaternion = simd_quatf(rotationMatrix)
    }
  }
  var scale: Float = 1
  var quaternion = simd_quatf()
}

extension Transform {
  var modelMatrix: matrix_float4x4 {
    let translation = float4x4(translation: position)
    let rotation = float4x4(quaternion)
    let scale = float4x4(scaling: scale)
    let modelMatrix = translation * rotation * scale
    return modelMatrix
  }
}

protocol Transformable {
  var transform: Transform { get set }
}

extension Transformable {
  var position: float3 {
    get { transform.position }
    set { transform.position = newValue }
  }
  var rotation: float3 {
    get { transform.rotation }
    set { transform.rotation = newValue }
  }
  var scale: Float {
    get { transform.scale }
    set { transform.scale = newValue }
  }
  var quaternion: simd_quatf {
    get { transform.quaternion }
    set { transform.quaternion = newValue }
  }
}
