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

class InputController {
  var player: Node?
  var currentSpeed: Float = 0
  
  
  var rotationSpeed: Float = 4.0
  var translationSpeed: Float = 0.05 {
    didSet {
      if translationSpeed > maxSpeed {
        translationSpeed = maxSpeed
      }
    }
  }
  let maxSpeed: Float = 0.1
  var currentTurnSpeed: Float = 0
  var currentPitch: Float = 0
  var forward = false
  
  // conforming to macOS
  var keyboardDelegate: Any?
}


extension InputController {
  func processEvent(touches: Set<UITouch>, state: InputState, event: UIEvent?) {
    switch state {
    case .began, .moved:
      forward = true
    case .ended:
      forward = false
    default:
      break
    }
  }
  public func updatePlayer(deltaTime: Float) {
    guard let player = player else { return }
    let translationSpeed = deltaTime * self.translationSpeed
    currentSpeed = forward ? currentSpeed + translationSpeed :
      currentSpeed - translationSpeed * 2
    if currentSpeed < 0 {
      currentSpeed = 0
    } else if currentSpeed > maxSpeed {
      currentSpeed = maxSpeed
    }
    player.rotation.y += currentPitch * deltaTime * rotationSpeed
    player.position.x += currentSpeed * sin(player.rotation.y)
    player.position.z += currentSpeed * cos(player.rotation.y)
  }
}

enum InputState {
  case began, moved, ended, cancelled, continued
}
