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

import GameController
// swiftlint:disable identifier_name

class InputController {
  struct Point {
    var x: Float
    var y: Float
    static let zero = Point(x: 0, y: 0)
  }

  var leftMouseDown = false
  var mouseDelta = Point.zero
  var mouseScroll = Point.zero
  var touchLocation: CGPoint?
  var touchDelta: CGSize? {
    didSet {
      touchDelta?.height *= -1
      if let delta = touchDelta {
        mouseDelta = Point(x: Float(delta.width), y: Float(delta.height))
      }
      leftMouseDown = touchDelta != nil
    }
  }

  static let shared = InputController()
  var keysPressed: Set<GCKeyCode> = []

  private init() {
    let center = NotificationCenter.default
    center.addObserver(
      forName: .GCKeyboardDidConnect,
      object: nil,
      queue: nil) { notification in
        let keyboard = notification.object as? GCKeyboard
          keyboard?.keyboardInput?.keyChangedHandler
            = { _, _, keyCode, pressed in
          if pressed {
            self.keysPressed.insert(keyCode)
          } else {
            self.keysPressed.remove(keyCode)
          }
        }
    }
#if os(macOS)
  NSEvent.addLocalMonitorForEvents(
    matching: [.keyUp, .keyDown]) { _ in nil }
#endif
    center.addObserver(
      forName: .GCMouseDidConnect,
      object: nil,
      queue: nil) { notification in
        let mouse = notification.object as? GCMouse
        mouse?.mouseInput?.leftButton.pressedChangedHandler = { _, _, pressed in
          self.leftMouseDown = pressed
        }
        mouse?.mouseInput?.mouseMovedHandler = { _, deltaX, deltaY in
          self.mouseDelta = Point(x: deltaX, y: deltaY)
        }
        mouse?.mouseInput?.scroll.valueChangedHandler = { _, xValue, yValue in
          self.mouseScroll.x = xValue
          self.mouseScroll.y = yValue
        }
    }
  }
}

// swiftlint:enable identifier_name
