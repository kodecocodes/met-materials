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

enum Settings {
  static var rotationSpeed: Float { 2.0 }
  static var translationSpeed: Float { 3.0 }
  static var mouseScrollSensitivity: Float { 0.1 }
  static var mousePanSensitivity: Float { 0.008 }
}

protocol Movement where Self: Transformable {
}

extension Movement {
  var forwardVector: float3 {
    normalize([sin(rotation.y), 0, cos(rotation.y)])
  }

  var rightVector: float3 {
    [forwardVector.z, forwardVector.y, -forwardVector.x]
  }

  func updateInput(deltaTime: Float) -> Transform {
    var transform = Transform()
    let rotationAmount = deltaTime * Settings.rotationSpeed
    let input = InputController.shared
    if input.keysPressed.contains(.leftArrow) {
      transform.rotation.y -= rotationAmount
    }
    if input.keysPressed.contains(.rightArrow) {
      transform.rotation.y += rotationAmount
    }
    var direction: float3 = .zero
    if input.keysPressed.contains(.keyW) {
      direction.z += 1
    }
    if input.keysPressed.contains(.keyS) {
      direction.z -= 1
    }
    if input.keysPressed.contains(.keyA) {
      direction.x -= 1
    }
    if input.keysPressed.contains(.keyD) {
      direction.x += 1
    }
    let translationAmount = deltaTime * Settings.translationSpeed
    if direction != .zero {
      direction = normalize(direction)
      transform.position += (direction.z * forwardVector
        + direction.x * rightVector) * translationAmount
    }
    return transform
  }
}
