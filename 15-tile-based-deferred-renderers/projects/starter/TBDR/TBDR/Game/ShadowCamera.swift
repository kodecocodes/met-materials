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

struct FrustumPoints {
  var viewMatrix = float4x4.identity
  var upperLeft = float3.zero
  var upperRight = float3.zero
  var lowerRight = float3.zero
  var lowerLeft = float3.zero
}

extension Camera {
  static func createShadowCamera(using camera: Camera, lightPosition: float3) -> OrthographicCamera {
    guard let camera = camera as? ArcballCamera else { return OrthographicCamera() }
    let nearPoints = calculatePlane(camera: camera, distance: camera.near)
    let farPoints = calculatePlane(camera: camera, distance: camera.far)

    // calculate bounding sphere of camera
    let radius1 = distance(nearPoints.lowerLeft, farPoints.upperRight) * 0.5
    let radius2 = distance(farPoints.lowerLeft, farPoints.upperRight) * 0.5
    var center: float3
    if radius1 > radius2 {
      center = simd_mix(nearPoints.lowerLeft, farPoints.upperRight, [0.5, 0.5, 0.5])
    } else {
      center = simd_mix(farPoints.lowerLeft, farPoints.upperRight, [0.5, 0.5, 0.5])
    }
    let radius = max(radius1, radius2)

    // create shadow camera using bounding sphere
    var shadowCamera = OrthographicCamera()
    let direction = normalize(lightPosition)
    shadowCamera.position = center + direction * radius
    shadowCamera.far = radius * 2
    shadowCamera.near = 0.01
    shadowCamera.viewSize = CGFloat(shadowCamera.far)
    shadowCamera.center = center
    return shadowCamera
  }

  static func calculatePlane(camera: ArcballCamera, distance: Float) -> FrustumPoints {
    let halfFov = camera.fov * 0.5
    let halfHeight = tan(halfFov) * distance
    let halfWidth = halfHeight * camera.aspect
    return calculatePlanePoints(
      matrix: camera.viewMatrix,
      halfWidth: halfWidth,
      halfHeight: halfHeight,
      distance: distance,
      position: camera.position)
  }

  static func calculatePlane(camera: OrthographicCamera, distance: Float) -> FrustumPoints {
    let aspect = Float(camera.aspect)
    let halfHeight = Float(camera.viewSize * 0.5)
    let halfWidth = halfHeight * aspect
    let matrix = float4x4(
      eye: camera.position,
      center: camera.center,
      up: [0, 1, 0])
    return calculatePlanePoints(
      matrix: matrix,
      halfWidth: halfWidth,
      halfHeight: halfHeight,
      distance: distance,
      position: camera.position)
  }

  private static func calculatePlanePoints(
    matrix: float4x4,
    halfWidth: Float,
    halfHeight: Float,
    distance: Float,
    position: float3
  ) -> FrustumPoints {
    let forwardVector: float3 = [matrix.columns.0.z, matrix.columns.1.z, matrix.columns.2.z]
    let rightVector: float3 = [matrix.columns.0.x, matrix.columns.1.x, matrix.columns.2.x]
    let upVector = cross(forwardVector, rightVector)
    let centerPoint = position + forwardVector * distance
    let moveRightBy = rightVector * halfWidth
    let moveDownBy = upVector * halfHeight

    let upperLeft = centerPoint - moveRightBy + moveDownBy
    let upperRight = centerPoint + moveRightBy + moveDownBy
    let lowerRight = centerPoint + moveRightBy - moveDownBy
    let lowerLeft = centerPoint - moveRightBy - moveDownBy
    let points = FrustumPoints(
      viewMatrix: matrix,
      upperLeft: upperLeft,
      upperRight: upperRight,
      lowerRight: lowerRight,
      lowerLeft: lowerLeft)
    return points
  }
}
