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

class Model: Node {

  let pipelineState: MTLRenderPipelineState
  var tiling: UInt32 = 1
  var vertexBuffer: MTLBuffer!
  let colorTexture: MTLTexture?
  let normalTexture: MTLTexture?
  let submesh: MTKSubmesh
  
  let vertexFunction: MTLFunction
  let fragmentFunction: MTLFunction

  init(name: String) {
    guard
      let assetUrl = Bundle.main.url(forResource: name, withExtension: nil) else {
        fatalError("Model: \(name) not found")
    }
    let allocator = MTKMeshBufferAllocator(device: Renderer.device)
    let asset = MDLAsset(url: assetUrl,
                         vertexDescriptor: MDLVertexDescriptor.defaultVertexDescriptor,
                         bufferAllocator: allocator)
    let (mdlMeshes, mtkMeshes) = try! MTKMesh.newMeshes(asset: asset,
                                                        device: Renderer.device)
    let meshes = zip(mdlMeshes, mtkMeshes).map {
      Mesh(mdlMesh: $0.0, mtkMesh: $0.1)
    }

    vertexFunction = Renderer.library.makeFunction(name: "vertex_main")!
    fragmentFunction = Renderer.library.makeFunction(name: "fragment_main")!
    pipelineState = Model.buildPipelineState(vertexFunction: vertexFunction,
                                             fragmentFunction: fragmentFunction)
    vertexBuffer = meshes[0].mtkMesh.vertexBuffers[0].buffer
    submesh = meshes[0].submeshes[0].mtkSubmesh
    let textures = meshes[0].submeshes[0].textures
    colorTexture = textures.baseColor
    normalTexture = textures.normal
    super.init()
    self.name = name
  }
  
  private static func buildPipelineState(vertexFunction: MTLFunction,
                                         fragmentFunction: MTLFunction) -> MTLRenderPipelineState {
    var pipelineState: MTLRenderPipelineState
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    let vertexDescriptor = MDLVertexDescriptor.defaultVertexDescriptor
    pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
    pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    do {
      pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
    return pipelineState
  }
}



