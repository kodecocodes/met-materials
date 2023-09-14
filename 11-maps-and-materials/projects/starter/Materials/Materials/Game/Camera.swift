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

import CoreGraphics

protocol Camera: Transformable {
  var projectionMatrix: float4x4 { get }
  var viewMatrix: float4x4 { get }
  mutating func update(size: CGSize)
  mutating func update(deltaTime: Float)
}

struct FPCamera: Camera {
  var transform = Transform()
  var aspect: Float = 1.0
  var fov = Float(70).degreesToRadians
  var near: Float = 0.1
  var far: Float = 100
  var projectionMatrix: float4x4 {
    float4x4(
      projectionFov: fov,
      near: near,
      far: far,
      aspect: aspect)
  }

  mutating func update(size: CGSize) {
    aspect = Float(size.width / size.height)
  }

  var viewMatrix: float4x4 {
    (float4x4(translation: position) *
    float4x4(rotation: rotation)).inverse
  }

  mutating func update(deltaTime: Float) {
    let transform = updateInput(deltaTime: deltaTime)
    rotation += transform.rotation
    position += transform.position
  }
}

extension FPCamera: Movement { }

struct ArcballCamera: Camera {
  var transform = Transform()
  var aspect: Float = 1.0
  var fov = Float(70).degreesToRadians
  var near: Float = 0.1
  var far: Float = 100
  var projectionMatrix: float4x4 {
    float4x4(
      projectionFov: fov,
      near: near,
      far: far,
      aspect: aspect)
  }
  let minDistance: Float = 0.0
  let maxDistance: Float = 20
  var target: float3 = [0, 0, 0]
  var distance: Float = 2.5

  mutating func update(size: CGSize) {
    aspect = Float(size.width / size.height)
  }

  var viewMatrix: float4x4 {
    let matrix: float4x4
    if target == position {
      matrix = (float4x4(translation: target) * float4x4(rotationYXZ: rotation)).inverse
    } else {
      matrix = float4x4(eye: position, center: target, up: [0, 1, 0])
    }
    return matrix
  }

  mutating func update(deltaTime: Float) {
    let input = InputController.shared
    let scrollSensitivity = Settings.mouseScrollSensitivity
    distance -= (input.mouseScroll.x + input.mouseScroll.y)
      * scrollSensitivity
    distance = min(maxDistance, distance)
    distance = max(minDistance, distance)
    input.mouseScroll = .zero
    if input.leftMouseDown {
      let sensitivity = Settings.mousePanSensitivity
      rotation.x += input.mouseDelta.y * sensitivity
      rotation.y += input.mouseDelta.x * sensitivity
      rotation.x = max(-.pi / 2, min(rotation.x, .pi / 2))
      input.mouseDelta = .zero
    }
    let rotateMatrix = float4x4(
      rotationYXZ: [-rotation.x, rotation.y, 0])
    let distanceVector = float4(0, 0, -distance, 0)
    let rotatedVector = rotateMatrix * distanceVector
    position = target + rotatedVector.xyz
  }
}

struct OrthographicCamera: Camera, Movement {
  var transform = Transform()
  var aspect: CGFloat = 1
  var viewSize: CGFloat = 10
  var near: Float = 0.1
  var far: Float = 100

  var viewMatrix: float4x4 {
    (float4x4(translation: position) *
    float4x4(rotation: rotation)).inverse
  }

  var projectionMatrix: float4x4 {
    let rect = CGRect(
      x: -viewSize * aspect * 0.5,
      y: viewSize * 0.5,
      width: viewSize * aspect,
      height: viewSize)
    return float4x4(orthographic: rect, near: near, far: far)
  }

  mutating func update(size: CGSize) {
    aspect = size.width / size.height
  }

  mutating func update(deltaTime: Float) {
    let transform = updateInput(deltaTime: deltaTime)
    position += transform.position
    let input = InputController.shared
    let zoom = input.mouseScroll.x + input.mouseScroll.y
    viewSize -= CGFloat(zoom)
    input.mouseScroll = .zero
  }
}
