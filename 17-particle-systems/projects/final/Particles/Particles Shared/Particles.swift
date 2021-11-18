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


import CoreGraphics
import simd

extension Renderer {
  func fire(size: CGSize) -> Emitter {
    let emitter = Emitter()
    emitter.particleCount = 1200
    emitter.particleTexture = Emitter.loadTexture(imageName: "fire")!
    emitter.birthRate = 5
    var descriptor = ParticleDescriptor()
    descriptor.position.x = Float(size.width) / 2 - 90
    descriptor.positionXRange = 0...180
    descriptor.direction = Float.pi / 2
    descriptor.directionRange = -0.3...0.3
    descriptor.speed = 3
    descriptor.pointSize = 80
    descriptor.startScale = 0
    descriptor.startScaleRange = 0.5...1.0
    descriptor.endScaleRange = 0...0
    descriptor.life = 180
    descriptor.lifeRange = -50...70
    descriptor.color = float4(1.0, 0.392, 0.1, 0.5);
    emitter.particleDescriptor = descriptor
    return emitter
  }
  
  func snow(size: CGSize) -> Emitter {
    let emitter = Emitter()
    
    // 1
    emitter.particleCount = 100
    emitter.birthRate = 1
    emitter.birthDelay = 20
    
    // 2
    emitter.particleTexture = Emitter.loadTexture(imageName: "snowflake")!
    
    // 3
    var descriptor = ParticleDescriptor()
    descriptor.position.x = 0
    descriptor.positionXRange = 0...Float(size.width)
    descriptor.direction = -.pi / 2
    descriptor.speedRange =  2...6
    descriptor.pointSizeRange = 80 * 0.5...80
    descriptor.startScale = 0
    descriptor.startScaleRange = 0.2...1.0
    
    // 4
    descriptor.life = 500
    descriptor.color = [1, 1, 1, 1]
    emitter.particleDescriptor = descriptor
    return emitter
  }

}
