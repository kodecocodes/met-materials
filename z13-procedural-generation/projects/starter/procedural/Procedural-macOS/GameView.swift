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


import MetalKit

class GameView: MTKView {
  weak var inputController: InputController?
  
  // for mouse movement
  var trackingArea : NSTrackingArea?
  var useMouse = false {
    didSet {
      inputController?.useMouse = useMouse
    }
  }
  
  override func updateTrackingAreas() {
    guard let window = NSApplication.shared.mainWindow else { return }
    window.acceptsMouseMovedEvents = useMouse
    if useMouse {
      CGDisplayHideCursor(CGMainDisplayID())
    } else {
      CGDisplayShowCursor(CGMainDisplayID())
    }
    if let trackingArea = trackingArea {
      removeTrackingArea(trackingArea)
    }
    guard useMouse else { return }
    let options: NSTrackingArea.Options = [.activeAlways, .inVisibleRect,  .mouseMoved]
    trackingArea = NSTrackingArea(rect: self.bounds, options: options,
                                  owner: self, userInfo: nil)
    addTrackingArea(trackingArea!)
  }
  
}

extension GameView {
  override var acceptsFirstResponder: Bool {
    return true
  }
  override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
    return true
  }
  
  override func keyDown(with event: NSEvent) {
    guard let key = KeyboardControl(rawValue: event.keyCode) else {
      return
    }
    let state: InputState = event.isARepeat ? .continued : .began
    inputController?.processEvent(key: key, state: state)
  }
  
  override func keyUp(with event: NSEvent) {
    guard let key = KeyboardControl(rawValue: event.keyCode) else {
      return
    }
    inputController?.processEvent(key: key, state: .ended)
  }
  
  override func mouseMoved(with event: NSEvent) {
    inputController?.processEvent(mouse: .mouseMoved, state: .began, event: event)
    // reset mouse position to center of view
    guard useMouse else { return }
    let screenFrame = NSScreen.main?.frame ?? .zero
    var rect = frame
    frame = convert(rect, to: nil)
    rect = window?.convertToScreen(rect) ?? rect
    CGWarpMouseCursorPosition(NSPoint(x: (rect.origin.x + bounds.midX),
                                      y: (screenFrame.height - rect.origin.y - bounds.midY) ))
  }
  
  
  override func mouseDown(with event: NSEvent) {
    inputController?.processEvent(mouse: .leftDown, state: .began, event: event)
  }
  
  override func mouseUp(with event: NSEvent) {
    inputController?.processEvent(mouse: .leftUp, state: .ended, event: event)
  }
  
  override func mouseDragged(with event: NSEvent) {
    inputController?.processEvent(mouse: .leftDrag, state: .continued, event: event)
  }
  
  override func rightMouseDown(with event: NSEvent) {
    inputController?.processEvent(mouse: .rightDown, state: .began, event: event)
  }
  
  override func rightMouseDragged(with event: NSEvent) {
    inputController?.processEvent(mouse: .rightDrag, state: .continued, event: event)
  }
  
  override func rightMouseUp(with event: NSEvent) {
    inputController?.processEvent(mouse: .rightUp, state: .ended, event: event)
  }
  
//  override func scrollWheel(with event: NSEvent) {
//    inputController?.processEvent(mouse: .scroll, state: .continued, event: event)
//  }
}
