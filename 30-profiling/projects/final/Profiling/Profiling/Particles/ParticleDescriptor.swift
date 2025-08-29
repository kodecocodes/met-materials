///// Copyright (c) 2025 Kodeco Inc.
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

struct ParticleDescriptor {
  var position: float3 = .zero
  var positionXRange: ClosedRange<Float> = 0...0
  var positionYRange: ClosedRange<Float> = 0...0
  var positionZRange: ClosedRange<Float> = 0...0

  var initialVelocity: float3 = .zero
  var velocityXRange: ClosedRange<Float> = 0...0
  var velocityYRange: ClosedRange<Float> = 0...0
  var velocityZRange: ClosedRange<Float> = 0...0

  var gravity: float3 = .zero
  var windForce: float3 = .zero
  var damping: Float = 0

  var pointSize: Float = 80
  var pointSizeRange: ClosedRange<Float> = 0...0
  var startScale: Float = 0
  var startScaleRange: ClosedRange<Float> = 1...1
  var endScale: Float = 0
  var endScaleRange: ClosedRange<Float>?
  var life: Float = 0
  var lifeRange: ClosedRange<Float> = 1...1
  var color: float4 = [0, 0, 0, 1]

  var rotationRange: ClosedRange<Float> = 0...0
  var angularVelocityRange: ClosedRange<Float> = 0...0
}

enum ParticleEffects {
  static func createFire(size: CGSize) -> Emitter {
    var descriptor = ParticleDescriptor()

    let halfFirePitSize: Float = 0.4
    descriptor.positionXRange = -halfFirePitSize...halfFirePitSize
    descriptor.positionYRange = 0...0
    descriptor.positionZRange = descriptor.positionXRange

    descriptor.initialVelocity = [0, 2.0, 0]
    descriptor.velocityXRange = -1...1
    descriptor.velocityYRange = 0...0
    descriptor.velocityZRange = -1...1

    descriptor.gravity = [0, -0.03, 0]
    descriptor.windForce = [0.02, 0, 0.01]
    descriptor.damping = 0.985

    descriptor.pointSize = 20
    descriptor.startScale = 0.3
    descriptor.startScaleRange = 0.5...1.2
    descriptor.endScale = 0
    descriptor.endScaleRange = 0...0.1
    descriptor.life = 60
    descriptor.lifeRange = -20...40
    descriptor.color = float4(1.0, 0.392, 0.1, 0.8)

    descriptor.rotationRange = 0...Float.pi * 2
    descriptor.angularVelocityRange = -0.05...0.5
    return Emitter(
      descriptor,
      texture: "fire",
      particleCount: 1200,
      birthRate: 5,
      birthDelay: 0,
      blending: true)
  }
}
