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

class GameView: MTKView {
  var inputController: InputController?
  var motionController = MotionController()
  @IBOutlet weak var acceleratorView: UIView!
  var isTouched = false
}

extension GameView {
  override func didMoveToWindow() {
    super.didMoveToWindow()
    motionController.motionClosure = {
      motion, error in
      guard let motion = motion else { return }
      let gravityAngle = atan2(motion.gravity.y, motion.gravity.x)
      let sign: Float = abs(gravityAngle) <= 1 ? -1 : 1
      let sensitivity: Float = 60
      self.inputController?.currentTurnSpeed = sign * Float(motion.attitude.pitch) * sensitivity
      self.inputController?.currentPitch = sign * Float(motion.attitude.pitch)
    }
    motionController.setupCoreMotion()
  }
  
  override func touchesBegan(_ touches: Set<UITouch>,
                             with event: UIEvent?) {
    
    // only process touch in accelerator view
    if let location = touches.first?.location(in: acceleratorView) {
      if location.x >= 0 && location.y >= 0 &&
        location.x < acceleratorView.bounds.width &&
        location.y < acceleratorView.bounds.height {
        isTouched = true
        inputController?.processEvent(touches: touches, state: .began, event: event)
      }
    }
    super.touchesBegan(touches, with: event)
  }
  
  override func touchesMoved(_ touches: Set<UITouch>,
                             with event: UIEvent?) {
    if isTouched {
      inputController?.processEvent(touches: touches, state: .moved, event: event)
    }
    super.touchesMoved(touches, with: event)
  }
  
  override func touchesEnded(_ touches: Set<UITouch>,
                             with event: UIEvent?) {
    if isTouched {
      inputController?.processEvent(touches: touches, state: .ended, event: event)
    }
    isTouched = false
    super.touchesEnded(touches, with: event)
  }
  
  override func touchesCancelled(_ touches: Set<UITouch>,
                                 with event: UIEvent?) {
    isTouched = false
    super.touchesCancelled(touches, with: event)
  }
}


