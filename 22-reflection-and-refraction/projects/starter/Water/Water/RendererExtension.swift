///// Copyright (c) 2019 Razeware LLC
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
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import MetalKit

extension Renderer {
  func zoomUsing(delta: CGFloat) {
    let sensitivity = Float(0.1)
    let result = camera.transform.position.y + Float(delta) * sensitivity
    if result > camera.minY {
      camera.transform.position.y = result
    }
  }
  
  func rotateUsing(translation: float2) {
    let sensitivity: Float = 0.01
    camera.transform.rotation.x += translation.y * sensitivity
    camera.transform.rotation.y -= translation.x * sensitivity
  }
}

extension Renderer {
  static func loadTexture(imageName: String) throws -> MTLTexture {
    let textureLoader = MTKTextureLoader(device: Renderer.device)
    let textureLoaderOptions: [MTKTextureLoader.Option: Any] =
      [.origin: MTKTextureLoader.Origin.bottomLeft,
       .SRGB: false,
       .generateMipmaps: NSNumber(booleanLiteral: false)]
    
    let fileExtension =
      URL(fileURLWithPath: imageName).pathExtension.isEmpty ?
        "png" : nil
    guard let url = Bundle.main.url(forResource: imageName,
                                    withExtension: fileExtension) else {
                                      fatalError("texture \(imageName) not found")
    }
    return try textureLoader.newTexture(URL: url,
                                        options: textureLoaderOptions)
  }

  func loadModel(name: String) -> MTKMesh {
    guard let assetURL = Bundle.main.url(forResource: name, withExtension: "obj")
      else { fatalError("Model not found") }
    
    let vertexDescriptor = MTLVertexDescriptor()
    
    var offset = 0
    vertexDescriptor.attributes[0].format = .float3
    vertexDescriptor.attributes[0].offset = 0
    vertexDescriptor.attributes[0].bufferIndex = 0
    offset += MemoryLayout<float3>.stride
    
    vertexDescriptor.attributes[1].format = .float3
    vertexDescriptor.attributes[1].offset = offset
    vertexDescriptor.attributes[1].bufferIndex = 0
    offset += MemoryLayout<float3>.stride
    
    vertexDescriptor.attributes[2].format = .float2
    vertexDescriptor.attributes[2].offset = offset
    vertexDescriptor.attributes[2].bufferIndex = 0
    offset += MemoryLayout<float3>.stride
    
    vertexDescriptor.layouts[0].stride = offset
    
    let descriptor = MTKModelIOVertexDescriptorFromMetal(vertexDescriptor)
    
    (descriptor.attributes[0] as! MDLVertexAttribute).name = MDLVertexAttributePosition
    (descriptor.attributes[1] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
    (descriptor.attributes[2] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
    
    let bufferAllocator = MTKMeshBufferAllocator(device: Renderer.device)
    let asset = MDLAsset(url: assetURL,
                         vertexDescriptor: descriptor,
                         bufferAllocator: bufferAllocator)
    let mdlMesh = asset.object(at: 0) as! MDLMesh
    let mtkMesh: MTKMesh
    do {
      mtkMesh = try MTKMesh(mesh: mdlMesh, device: Renderer.device)
    } catch {
      fatalError(error.localizedDescription)
    }
    return mtkMesh
  }
  
  func loadSkyboxTexture() -> MTLTexture? {
    var texture: MTLTexture?
    let textureLoader = MTKTextureLoader(device: Renderer.device)
    if let mdlTexture = MDLTexture(cubeWithImagesNamed:
      ["posx.png", "negx.png", "posy.png", "negy.png", "posz.png", "negz.png"]) {
      do {
        texture = try textureLoader.newTexture(texture: mdlTexture, options: nil)
      } catch {
        print("no texture created")
      }
    } else {
      print("texture image not found")
    }
    return texture
  }
}
