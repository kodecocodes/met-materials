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

import CoreMotion
import simd

class MotionController {
  let motionManager = CMMotionManager()
  var motionClosure: ((CMDeviceMotion?, Error?) -> Void)?
  var acceleration: float3 = [0, 0, 0]
  var previousAcceleration: float3 = [0, 0, 0]
  
  var deltaAcceleration: float3 {
    return previousAcceleration - acceleration
  }
  
  func setupCoreMotion() {
    motionManager.accelerometerUpdateInterval = 0.2
    let queue = OperationQueue()
    
    motionManager.startDeviceMotionUpdates(to: queue, withHandler: {
      motion, error in
      self.motionClosure?(motion, error)
    })
    motionManager.startAccelerometerUpdates(to: queue, withHandler: {
      accelerometerData, error in
      guard let accelerometerData = accelerometerData else { return }
      let acceleration = accelerometerData.acceleration
      self.previousAcceleration = self.acceleration
      self.acceleration.x = (Float(acceleration.x) * 0.75) + (self.acceleration.x * 0.25)
      self.acceleration.y = (Float(acceleration.y) * 0.75) + (self.acceleration.y * 0.25)
      self.acceleration.z = (Float(acceleration.z) * 0.75) + (self.acceleration.z * 0.25)
    })
  }
}
