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
import CoreImage

let imageNames = ["posx.png", "negx.png", "posy.png", "negy.png", "posz.png", "negz.png"]
let mipLevels = 9
let directoryPath = "specular"

class ViewController: NSViewController {
  
  @IBOutlet weak var notificationLabel: NSTextField!

  let device: MTLDevice
  let library: MTLLibrary?
  let commandQueue: MTLCommandQueue
  
  let cubeTexture: MTLTexture
  let cubeSize: (width: Int, height: Int)
  
  required init?(coder: NSCoder) {
    device = MTLCreateSystemDefaultDevice()!
    library = device.makeDefaultLibrary()
    commandQueue = device.makeCommandQueue()!

    cubeTexture = try! ViewController.loadCubeTexture(device: device, imageNames: imageNames)!
    cubeSize.width = cubeTexture.width
    cubeSize.height = cubeTexture.height
    super.init(coder: coder)
  }
  
  override func viewDidAppear() {
    super.viewDidAppear()
    for level in 1..<mipLevels {
      if let outputTexture = process(level: level, imageNames: imageNames) {
        write(texture: outputTexture, filename: "specular-" + "\(level)")
      }
      
    }
  }

  func process(level: Int, imageNames: [String]) -> MTLTexture? {
    print("Processing level: ", level)

    guard let function = library?.makeFunction(name: "build_specular"),
      let pipelineState = try? device.makeComputePipelineState(function: function),
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { fatalError() }
    
    defer {
      commandEncoder.endEncoding()
      commandBuffer.commit()
    }
    
    let size = cubeSize.width / Int(pow(2, Float(level)))
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                       width: size,
                                                       height: size * 6,
                                                       mipmapped: false)
    descriptor.usage = [.shaderRead, .shaderWrite]
    let outputTexture = device.makeTexture(descriptor: descriptor)
    let inputTexture = cubeTexture
    
    commandEncoder.setComputePipelineState(pipelineState)
    commandEncoder.setTexture(inputTexture, index: 0)
    commandEncoder.setTexture(outputTexture, index: 1)

    var roughness: Float = Float(level) / 10
    commandEncoder.setBytes(&roughness, length: MemoryLayout<Float>.stride, index: 0)

    let threadsPerThreadgroup = MTLSizeMake(min(size, 16), min(size, 16), 1)
    let threadgroups = MTLSizeMake(inputTexture.width / threadsPerThreadgroup.width,
                                   inputTexture.width / threadsPerThreadgroup.height, 6)
    commandEncoder.dispatchThreadgroups(threadgroups,
                                        threadsPerThreadgroup: threadsPerThreadgroup)
    return outputTexture
  }
  
  static func loadCubeTexture(device: MTLDevice, imageNames: [String]) throws -> MTLTexture? {
    let textureLoader = MTKTextureLoader(device: device)
    if let texture = MDLTexture(cubeWithImagesNamed: imageNames) {
      let options: [MTKTextureLoader.Option: Any] =
        [.origin: MTKTextureLoader.Origin.topLeft,
         .SRGB: false,
         .generateMipmaps: NSNumber(booleanLiteral: true)]
      return try textureLoader.newTexture(texture: texture, options: options)
    }
    let texture = try textureLoader.newTexture(name: "cube texture", scaleFactor: 1.0,
                                               bundle: .main, options: nil)
    return texture
  }

  func write(texture: MTLTexture, filename: String) {
    // use Core Image to create the cgImage
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let ciimage = CIImage(mtlTexture: texture, options: [CIImageOption.colorSpace: colorSpace])
    let ciContext = CIContext(mtlDevice: device)
    
    // write six images for each level of roughness
    let faceNames = ["posX", "negX", "posY", "negY", "posZ", "negZ"]
    let size = CGFloat(texture.width)
    for i in 0..<6 {
      let y = size * CGFloat(i)
      guard let cgImage = ciContext.createCGImage(ciimage!, from: CGRect(x: 0, y: y,
                                                                         width: size,
                                                                         height: size)) else {
                                                                          fatalError("no texture image created")
      }
      let imageSize = CGSize(width: size, height: size)
      let image = NSImage(cgImage: cgImage, size: imageSize)
      let documentDirectoryURL = try! FileManager.default.url(for: .documentDirectory,
                                                              in: .userDomainMask,
                                                              appropriateFor: nil,
                                                              create: false)
      let path = documentDirectoryURL.appendingPathComponent(directoryPath)
      let url = URL(string: filename + "-\(faceNames[i]).png", relativeTo: path)!
      image.writePNG(to: url)
      notificationLabel.stringValue = "\(url.absoluteString)"
    }
  }
  
}

