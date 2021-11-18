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

import Cocoa
import simd

typealias float4 = SIMD4<Float>

class ViewController: NSViewController {

  @IBOutlet weak var typeBox: NSBox!
  var matrix = matrix_identity_float4x4
  var multiplier = matrix_identity_float4x4
  var isVector = false
  var result = matrix_identity_float4x4
  
  override func viewDidLoad() {
    super.viewDidLoad()
    displayMatrix()
  }

  override func viewWillAppear() {
    super.viewWillAppear()
    if let textField = view.viewWithTag(100) {
      textField.window?.makeFirstResponder(textField)
    }
  }

  func setIdentity() {
  }

  func displayMatrix() {
    typeBox.title = isVector ? "Vector" : "Matrix"

    (view.viewWithTag(100) as! NSTextField).stringValue = "\(matrix.columns.0.x)"
    (view.viewWithTag(101) as! NSTextField).stringValue = "\(matrix.columns.0.y)"
    (view.viewWithTag(102) as! NSTextField).stringValue = "\(matrix.columns.0.z)"
    (view.viewWithTag(103) as! NSTextField).stringValue = "\(matrix.columns.0.w)"

    (view.viewWithTag(104) as! NSTextField).stringValue = "\(matrix.columns.1.x)"
    (view.viewWithTag(105) as! NSTextField).stringValue = "\(matrix.columns.1.y)"
    (view.viewWithTag(106) as! NSTextField).stringValue = "\(matrix.columns.1.z)"
    (view.viewWithTag(107) as! NSTextField).stringValue = "\(matrix.columns.1.w)"

    (view.viewWithTag(108) as! NSTextField).stringValue = "\(matrix.columns.2.x)"
    (view.viewWithTag(109) as! NSTextField).stringValue = "\(matrix.columns.2.y)"
    (view.viewWithTag(110) as! NSTextField).stringValue = "\(matrix.columns.2.z)"
    (view.viewWithTag(111) as! NSTextField).stringValue = "\(matrix.columns.2.w)"

    (view.viewWithTag(112) as! NSTextField).stringValue = "\(matrix.columns.3.x)"
    (view.viewWithTag(113) as! NSTextField).stringValue = "\(matrix.columns.3.y)"
    (view.viewWithTag(114) as! NSTextField).stringValue = "\(matrix.columns.3.z)"
    (view.viewWithTag(115) as! NSTextField).stringValue = "\(matrix.columns.3.w)"

    (view.viewWithTag(200) as! NSTextField).stringValue = "\(multiplier.columns.0.x)"
    (view.viewWithTag(201) as! NSTextField).stringValue = "\(multiplier.columns.0.y)"
    (view.viewWithTag(202) as! NSTextField).stringValue = "\(multiplier.columns.0.z)"
    (view.viewWithTag(203) as! NSTextField).stringValue = "\(multiplier.columns.0.w)"
    
    (view.viewWithTag(204) as! NSTextField).stringValue = "\(multiplier.columns.1.x)"
    (view.viewWithTag(205) as! NSTextField).stringValue = "\(multiplier.columns.1.y)"
    (view.viewWithTag(206) as! NSTextField).stringValue = "\(multiplier.columns.1.z)"
    (view.viewWithTag(207) as! NSTextField).stringValue = "\(multiplier.columns.1.w)"
    
    (view.viewWithTag(208) as! NSTextField).stringValue = "\(multiplier.columns.2.x)"
    (view.viewWithTag(209) as! NSTextField).stringValue = "\(multiplier.columns.2.y)"
    (view.viewWithTag(210) as! NSTextField).stringValue = "\(multiplier.columns.2.z)"
    (view.viewWithTag(211) as! NSTextField).stringValue = "\(multiplier.columns.2.w)"
    
    (view.viewWithTag(212) as! NSTextField).stringValue = "\(multiplier.columns.3.x)"
    (view.viewWithTag(213) as! NSTextField).stringValue = "\(multiplier.columns.3.y)"
    (view.viewWithTag(214) as! NSTextField).stringValue = "\(multiplier.columns.3.z)"
    (view.viewWithTag(215) as! NSTextField).stringValue = "\(multiplier.columns.3.w)"

    (view.viewWithTag(300) as! NSTextField).stringValue = "\(result.columns.0.x)"
    (view.viewWithTag(301) as! NSTextField).stringValue = "\(result.columns.0.y)"
    (view.viewWithTag(302) as! NSTextField).stringValue = "\(result.columns.0.z)"
    (view.viewWithTag(303) as! NSTextField).stringValue = "\(result.columns.0.w)"
    
    (view.viewWithTag(304) as! NSTextField).stringValue = "\(result.columns.1.x)"
    (view.viewWithTag(305) as! NSTextField).stringValue = "\(result.columns.1.y)"
    (view.viewWithTag(306) as! NSTextField).stringValue = "\(result.columns.1.z)"
    (view.viewWithTag(307) as! NSTextField).stringValue = "\(result.columns.1.w)"
    
    (view.viewWithTag(308) as! NSTextField).stringValue = "\(result.columns.2.x)"
    (view.viewWithTag(309) as! NSTextField).stringValue = "\(result.columns.2.y)"
    (view.viewWithTag(310) as! NSTextField).stringValue = "\(result.columns.2.z)"
    (view.viewWithTag(311) as! NSTextField).stringValue = "\(result.columns.2.w)"
    
    (view.viewWithTag(312) as! NSTextField).stringValue = "\(result.columns.3.x)"
    (view.viewWithTag(313) as! NSTextField).stringValue = "\(result.columns.3.y)"
    (view.viewWithTag(314) as! NSTextField).stringValue = "\(result.columns.3.z)"
    (view.viewWithTag(315) as! NSTextField).stringValue = "\(result.columns.3.w)"

  }
  func matrixDisplay(isVector: Bool) {
    for i in 204..<216 {
      view.viewWithTag(i)?.isHidden = isVector
    }
    for i in 304..<316 {
      view.viewWithTag(i)?.isHidden = isVector
    }
    displayMatrix()
  }
  
  @IBAction func matrixType(sender: NSButton) {
    isVector = sender.tag == 10 ? true : false
    matrixDisplay(isVector: isVector)
  }
  
  func matrixCalculate() {
    matrix.columns.0.x = (view.viewWithTag(100)! as! NSTextField).floatValue
    matrix.columns.0.y = (view.viewWithTag(101)! as! NSTextField).floatValue
    matrix.columns.0.z = (view.viewWithTag(102)! as! NSTextField).floatValue
    matrix.columns.0.w = (view.viewWithTag(103)! as! NSTextField).floatValue

    matrix.columns.1.x = (view.viewWithTag(104)! as! NSTextField).floatValue
    matrix.columns.1.y = (view.viewWithTag(105)! as! NSTextField).floatValue
    matrix.columns.1.z = (view.viewWithTag(106)! as! NSTextField).floatValue
    matrix.columns.1.w = (view.viewWithTag(107)! as! NSTextField).floatValue

    matrix.columns.2.x = (view.viewWithTag(108)! as! NSTextField).floatValue
    matrix.columns.2.y = (view.viewWithTag(109)! as! NSTextField).floatValue
    matrix.columns.2.z = (view.viewWithTag(110)! as! NSTextField).floatValue
    matrix.columns.2.w = (view.viewWithTag(111)! as! NSTextField).floatValue

    matrix.columns.3.x = (view.viewWithTag(112)! as! NSTextField).floatValue
    matrix.columns.3.y = (view.viewWithTag(113)! as! NSTextField).floatValue
    matrix.columns.3.z = (view.viewWithTag(114)! as! NSTextField).floatValue
    matrix.columns.3.w = (view.viewWithTag(115)! as! NSTextField).floatValue

    if isVector {
      
      multiplier.columns.0.x = (view.viewWithTag(200)! as! NSTextField).floatValue
      multiplier.columns.0.y = (view.viewWithTag(201)! as! NSTextField).floatValue
      multiplier.columns.0.z = (view.viewWithTag(202)! as! NSTextField).floatValue
      multiplier.columns.0.w = (view.viewWithTag(203)! as! NSTextField).floatValue

      var vector: float4 = [0, 0, 0, 0]
      vector.x = (view.viewWithTag(200)! as! NSTextField).floatValue
      vector.y = (view.viewWithTag(201)! as! NSTextField).floatValue
      vector.z = (view.viewWithTag(202)! as! NSTextField).floatValue
      vector.w = (view.viewWithTag(203)! as! NSTextField).floatValue
      let resultVector = matrix * vector
      result.columns.0.x = resultVector.x
      result.columns.0.y = resultVector.y
      result.columns.0.z = resultVector.z
      result.columns.0.w = resultVector.w
    } else {
      multiplier.columns.0.x = (view.viewWithTag(200)! as! NSTextField).floatValue
      multiplier.columns.0.y = (view.viewWithTag(201)! as! NSTextField).floatValue
      multiplier.columns.0.z = (view.viewWithTag(202)! as! NSTextField).floatValue
      multiplier.columns.0.w = (view.viewWithTag(203)! as! NSTextField).floatValue
      
      multiplier.columns.1.x = (view.viewWithTag(204)! as! NSTextField).floatValue
      multiplier.columns.1.y = (view.viewWithTag(205)! as! NSTextField).floatValue
      multiplier.columns.1.z = (view.viewWithTag(206)! as! NSTextField).floatValue
      multiplier.columns.1.w = (view.viewWithTag(207)! as! NSTextField).floatValue
      
      multiplier.columns.2.x = (view.viewWithTag(208)! as! NSTextField).floatValue
      multiplier.columns.2.y = (view.viewWithTag(209)! as! NSTextField).floatValue
      multiplier.columns.2.z = (view.viewWithTag(210)! as! NSTextField).floatValue
      multiplier.columns.2.w = (view.viewWithTag(211)! as! NSTextField).floatValue
      
      multiplier.columns.3.x = (view.viewWithTag(212)! as! NSTextField).floatValue
      multiplier.columns.3.y = (view.viewWithTag(213)! as! NSTextField).floatValue
      multiplier.columns.3.z = (view.viewWithTag(214)! as! NSTextField).floatValue
      multiplier.columns.3.w = (view.viewWithTag(215)! as! NSTextField).floatValue
      
      result = matrix * multiplier
    }
    displayMatrix()
  }

  override var acceptsFirstResponder: Bool {
    return true
  }
}

extension ViewController: NSTextFieldDelegate {
  func controlTextDidEndEditing(_ obj: Notification) {
    matrixCalculate()
  }
}


