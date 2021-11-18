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

// v0.08 4 Aug 2019

import simd

typealias float2 = SIMD2<Float>
typealias float3 = SIMD3<Float>
typealias float4 = SIMD4<Float>

let π = Float.pi

struct Rectangle {
  var left: Float = 0
  var right: Float = 0
  var top: Float = 0
  var bottom: Float = 0
}

extension Float {
  var radiansToDegrees: Float {
    return (self / π) * 180
  }
  var degreesToRadians: Float {
    return (self / 180) * π
  }
}

extension float4x4 {
  init(translation: float3) {
    self = matrix_identity_float4x4
    columns.3.x = translation.x
    columns.3.y = translation.y
    columns.3.z = translation.z
  }
  
  init(scaling: float3) {
    self = matrix_identity_float4x4
    columns.0.x = scaling.x
    columns.1.y = scaling.y
    columns.2.z = scaling.z
  }
  
  init(scaling: Float) {
    self = matrix_identity_float4x4
    columns.3.w = 1 / scaling
  }
  
  init(rotationX angle: Float) {
    self = matrix_identity_float4x4
    columns.1.y = cos(angle)
    columns.1.z = sin(angle)
    columns.2.y = -sin(angle)
    columns.2.z = cos(angle)
  }
  
  init(rotationY angle: Float) {
    self = matrix_identity_float4x4
    columns.0.x = cos(angle)
    columns.0.z = -sin(angle)
    columns.2.x = sin(angle)
    columns.2.z = cos(angle)
  }
  
  init(rotationZ angle: Float) {
    self = matrix_identity_float4x4
    columns.0.x = cos(angle)
    columns.0.y = sin(angle)
    columns.1.x = -sin(angle)
    columns.1.y = cos(angle)
  }
  
  init(rotation angle: float3) {
    let rotationX = float4x4(rotationX: angle.x)
    let rotationY = float4x4(rotationY: angle.y)
    let rotationZ = float4x4(rotationZ: angle.z)
    self = rotationX * rotationY * rotationZ
  }
  
  static func identity() -> float4x4 {
    let matrix:float4x4 = matrix_identity_float4x4
    return matrix
  }
  
  func upperLeft() -> float3x3 {
    let x = columns.0.xyz
    let y = columns.1.xyz
    let z = columns.2.xyz
    return float3x3(columns: (x, y, z))
  }
  
  init(projectionFov fov: Float, near: Float, far: Float, aspect: Float, lhs: Bool = true) {
    let y = 1 / tan(fov * 0.5)
    let x = y / aspect
    let z = lhs ? far / (far - near) : far / (near - far)
    let X = float4( x,  0,  0,  0)
    let Y = float4( 0,  y,  0,  0)
    let Z = lhs ? float4( 0,  0,  z, 1) : float4( 0,  0,  z, -1)
    let W = lhs ? float4( 0,  0,  z * -near,  0) : float4( 0,  0,  z * near,  0)
    self.init()
    columns = (X, Y, Z, W)
  }
  
  // left-handed LookAt
  init(eye: float3, center: float3, up: float3) {
    let z = normalize(eye - center)
    let x = normalize(cross(up, z))
    let y = cross(z, x)
    let w = float3(dot(x, -eye), dot(y, -eye), dot(z, -eye))
    
    let X = float4(x.x, y.x, z.x, 0)
    let Y = float4(x.y, y.y, z.y, 0)
    let Z = float4(x.z, y.z, z.z, 0)
    let W = float4(w.x, w.y, x.z, 1)
    self.init()
    columns = (X, Y, Z, W)
  }
  
  init(orthographic rect: Rectangle, near: Float, far: Float) {
    let X = float4(2 / (rect.right - rect.left), 0, 0, 0)
    let Y = float4(0, 2 / (rect.top - rect.bottom), 0, 0)
    let Z = float4(0, 0, 1 / (far - near), 0)
    let W = float4((rect.left + rect.right) / (rect.left - rect.right),
                   (rect.top + rect.bottom) / (rect.bottom - rect.top),
                   near / (near - far),
                   1)
    self.init()
    columns = (X, Y, Z, W)
  }
}

extension float3x3 {
  init(normalFrom4x4 matrix: float4x4) {
    self.init()
    columns = matrix.upperLeft().inverse.transpose.columns
  }
}

extension float4 {
  var xyz: float3 {
    get {
      return float3(x, y, z)
    }
    set {
      x = newValue.x
      y = newValue.y
      z = newValue.z
    }
  }
  
  init(_ start: float3, _ end: Float) {
    self.init(start.x, start.y, start.z, end)
  }
}

extension float4x4: CustomStringConvertible {
  public var description: String {
    let s0x = String(format: "%.2f", columns.0.x)
    let s0y = String(format: "%.2f", columns.0.y)
    let s0z = String(format: "%.2f", columns.0.z)
    let s0w = String(format: "%.2f", columns.0.w)
    let s1x = String(format: "%.2f", columns.1.x)
    let s1y = String(format: "%.2f", columns.1.y)
    let s1z = String(format: "%.2f", columns.1.z)
    let s1w = String(format: "%.2f", columns.1.w)
    let s2x = String(format: "%.2f", columns.2.x)
    let s2y = String(format: "%.2f", columns.2.y)
    let s2z = String(format: "%.2f", columns.2.z)
    let s2w = String(format: "%.2f", columns.2.w)
    let s3x = String(format: "%.2f", columns.3.x)
    let s3y = String(format: "%.2f", columns.3.y)
    let s3z = String(format: "%.2f", columns.3.z)
    let s3w = String(format: "%.2f", columns.3.w)
    return "\nX: \(s0x), \t\(s1x), \t\(s2x), \t\(s3x)\nY: \(s0y), \t\(s1y), \t\(s2y), \t\(s3y)\nZ: \(s0z), \t\(s1z), \t\(s2z), \t\(s3z)\nW: \(s0w), \t\(s1w), \t\(s2w), \t\(s3w)\n"
  }
}
