import GameController

enum Settings {
  static var rotationSpeed: Float { 2.0 }
  static var translationSpeed: Float { 3.0 }
  static var mouseScrollSensitivity: Float { 0.1 }
  static var mousePanSensitivity: Float { 0.008 }
  static var touchZoomSensitivity: Float { 10 }
}

@MainActor
class InputController {
  struct Point {
    var x: Float
    var y: Float
    static let zero = Point(x: 0, y: 0)
  }

  var timer: Timer?
  var timerCount = 0

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
            Task { @MainActor in
              if pressed {
                self.keysPressed.insert(keyCode)
              } else {
                self.keysPressed.remove(keyCode)
              }
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
          // slight delay to ensure that this is a drag
          if pressed {
            Task { @MainActor in
              self.setTimer()
            }
          } else {
            Task { @MainActor in
              self.timer?.invalidate()
              self.leftMouseDown = false
            }
          }
        }
        mouse?.mouseInput?.mouseMovedHandler = { _, deltaX, deltaY in
          Task { @MainActor in
            self.mouseDelta = Point(x: deltaX, y: deltaY)
          }
        }
        mouse?.mouseInput?.scroll.valueChangedHandler = { _, xValue, yValue in
          Task { @MainActor in
            self.mouseScroll.x = xValue
            self.mouseScroll.y = yValue
          }
        }
    }
  }

// MARK: - Set timer to ensure that the mouse down is a drag

  func setTimer() {
    timerCount = 0
    timer = Timer.scheduledTimer(
      timeInterval: 0.1,
      target: self,
      selector: #selector(setMouseDown),
      userInfo: nil, repeats: true)
  }

  @objc func setMouseDown() {
    timerCount += 1
    if timerCount > 5 {
      timer?.invalidate()
      self.leftMouseDown = true
    }
  }
}
