/// Copyright (c) 2022 Razeware LLC
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

import MetalKit

enum TextureController {
  static var textures: [String: MTLTexture] = [:]

  static func texture(filename: String) -> MTLTexture? {
    if let texture = textures[filename] {
      return texture
    }
    let texture = try? loadTexture(filename: filename)
    if texture != nil {
      textures[filename] = texture
    }
    return texture
  }

  static func loadTexture(filename: String) throws -> MTLTexture? {
    // 1
    let textureLoader = MTKTextureLoader(device: Renderer.device)
    if let texture = try? textureLoader.newTexture(
      name: filename,
      scaleFactor: 1.0,
      bundle: Bundle.main,
      options: nil) {
      print("loaded texture: \(filename)")
      return texture
    }
    // 2
    let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [
      .origin: MTKTextureLoader.Origin.bottomLeft,
      .SRGB: false,
      .generateMipmaps: NSNumber(value: true)
    ]
    // 3
    let fileExtension =
      URL(fileURLWithPath: filename).pathExtension.isEmpty ?
        "png" : nil
    // 4
    guard let url = Bundle.main.url(
      forResource: filename,
      withExtension: fileExtension)
      else {
        print("Failed to load \(filename)")
        return nil
    }
    let texture = try textureLoader.newTexture(
      URL: url,
      options: textureLoaderOptions)
    print("loaded texture: \(url.lastPathComponent)")
    return texture
  }
}
