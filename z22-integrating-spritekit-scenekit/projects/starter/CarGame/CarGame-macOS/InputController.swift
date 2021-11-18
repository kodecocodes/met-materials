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


import Cocoa

protocol KeyboardDelegate {
  func keyPressed(key: KeyboardControl, state: InputState) -> Bool
}

protocol MouseDelegate {
  func mouseEvent(mouse: MouseControl, state: InputState,
                  delta: float3, location: float2)
}

class InputController {
  var keyboardDelegate: KeyboardDelegate?
  var directionKeysDown: Set<KeyboardControl> = []
  
  var player: Node?
  var translationSpeed: Float = 2.0
  var rotationSpeed: Float = 1.0
  
  var mouseDelegate: MouseDelegate?
  var useMouse = false
  
  public func updatePlayer(deltaTime: Float) {
    guard let player = player else { return }
    let translationSpeed = deltaTime * self.translationSpeed
    let rotationSpeed = deltaTime * self.rotationSpeed
    var direction: float3 = [0, 0, 0]
    for key in directionKeysDown {
      switch key {
      case .w:
        direction.z += 1
      case .a:
        direction.x -= 1
      case.s:
        direction.z -= 1
      case .d:
        direction.x += 1
      case .left, .q:
        player.rotation.y -= rotationSpeed
      case .right, .e:
        player.rotation.y += rotationSpeed
      default:
        break
      }
    }
    if direction != [0, 0, 0] {
      direction = normalize(direction)
      player.position +=
        (direction.z * player.forwardVector
          + direction.x * player.rightVector)
        * translationSpeed
    }
  }
  
  func processEvent(key inKey: KeyboardControl, state: InputState) {
    let key = inKey
    if !(keyboardDelegate?.keyPressed(key: key, state: state) ?? true) {
      return
    }
    if state == .began {
      directionKeysDown.insert(key)
    }
    if state == .ended {
      directionKeysDown.remove(key)
    }
  }
  
  func processEvent(mouse: MouseControl, state: InputState, event: NSEvent) {
    let delta: float3 = [Float(event.deltaX), Float(event.deltaY), Float(event.deltaZ)]
    let locationInWindow: float2 = [Float(event.locationInWindow.x), Float(event.locationInWindow.y)]
    mouseDelegate?.mouseEvent(mouse: mouse, state: state, delta: delta, location: locationInWindow)
  }
}

enum InputState {
  case began, moved, ended, cancelled, continued
}

enum KeyboardControl: UInt16 {
  case a =      0
  case d =      2
  case w =      13
  case s =      1
  case down =   125
  case up =     126
  case right =  124
  case left =   123
  case q =      12
  case e =      14
  case key1 =   18
  case key2 =   19
  case key0 =   29
  case space =  49
  case c =      8
}

enum MouseControl {
  case leftDown, leftUp, leftDrag, rightDown, rightUp, rightDrag, scroll, mouseMoved
}

