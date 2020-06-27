/**
 * Copyright (c) 2018 Razeware LLC
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

public class MetalView: MTKView {
  
  public var renderer: Renderer?
  
  public required init(coder: NSCoder) {
    fatalError()
  }
  
  public override init(frame: NSRect, device: MTLDevice?) {
    super.init(frame: frame, device: device)
    let pan = NSPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
    addGestureRecognizer(pan)
  }
  
  @objc public func handlePan(gesture: NSPanGestureRecognizer) {
    let translation = gesture.translation(in: self)
    renderer?.rotateUsing(translation: translation)
    gesture.setTranslation(.zero, in: self)
  }
  
  public override func scrollWheel(with event: NSEvent) {
    renderer?.zoomUsing(delta: event.deltaY)
  }
  
  public override var acceptsFirstResponder: Bool {
    return true
  }
  
  public override func keyDown(with event: NSEvent) {
    enum KeyCode: UInt16 {
      case a = 0
      case t = 0x11
      case b = 0xB
      case f = 0x3
    }
    
    guard
      let renderer = renderer,
      let keyCode = KeyCode(rawValue: event.keyCode)
      else {return}
    
    switch keyCode {
    case .t:
      renderer.transparencyEnabled = !renderer.transparencyEnabled
    case .b:
      renderer.blendingEnabled = !renderer.blendingEnabled
    case .a:
      renderer.antialiasingEnabled = !renderer.antialiasingEnabled
    case .f:
      renderer.fogEnabled = !renderer.fogEnabled
    }
  }
}
