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
let imageNames = ["posx.png", "negx.png", "posy.png", "negy.png", "posz.png", "negz.png"]
var dimensions: Int32 = 64
let level = 6

typealias int2 = SIMD2<Int32>

class ViewController: NSViewController {
  
  @IBOutlet weak var notificationLabel: NSTextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    print("Creating irradiance textures. Level ", level)
    loadTexture(level: level)
  }
  
  func loadTexture(level: Int) {
    let roughness: Float = Float(level) / 10
    guard let mdlTexture = MDLTexture(cubeWithImagesNamed: imageNames) else {
      fatalError("texture image not found")
    }
    let irradianceTexture =
      MDLTexture.irradianceTextureCube(with: mdlTexture,
                                       name: nil,
                                       dimensions: int2(dimensions, dimensions),
                                       roughness: roughness)
    
    guard let cgImage = irradianceTexture.imageFromTexture()?.takeUnretainedValue() else {
      fatalError("no irradiance image created")
    }
    let size = CGSize(width: CGFloat(dimensions), height: CGFloat(dimensions * 6))
    let image = NSImage(cgImage: cgImage, size: size)
    let documentDirectoryURL = try! FileManager.default.url(for: .documentDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: nil,
                                                            create: false)
    let url = URL(string: "irradiance-\(level).png", relativeTo: documentDirectoryURL)!
    image.writePNG(to: url)
    notificationLabel.stringValue = "\(url.absoluteString)"
  }
}
