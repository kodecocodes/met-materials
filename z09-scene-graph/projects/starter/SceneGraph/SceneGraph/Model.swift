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
  
  let meshes: [Mesh]
  var tiling: UInt32 = 1
  let samplerState: MTLSamplerState?
  static var vertexDescriptor: MDLVertexDescriptor = MDLVertexDescriptor.defaultVertexDescriptor

  var currentTime: Float = 0
  let animations: [String: AnimationClip]
  var currentAnimation: AnimationClip?
  var animationPaused = true
  
  let debugBoundingBox: DebugBoundingBox

  init(name: String) {
    guard
      let assetUrl = Bundle.main.url(forResource: name, withExtension: nil) else {
        fatalError("Model: \(name) not found")
    }
    let allocator = MTKMeshBufferAllocator(device: Renderer.device)
    let asset = MDLAsset(url: assetUrl,
                         vertexDescriptor: MDLVertexDescriptor.defaultVertexDescriptor,
                         bufferAllocator: allocator)
    
    // load Model I/O textures
    asset.loadTextures()
    
    // load meshes
    var mtkMeshes: [MTKMesh] = []
    let mdlMeshes = asset.childObjects(of: MDLMesh.self) as! [MDLMesh]
    _ = mdlMeshes.map { mdlMesh in
      mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed:
        MDLVertexAttributeTextureCoordinate,
                              tangentAttributeNamed: MDLVertexAttributeTangent,
                              bitangentAttributeNamed: MDLVertexAttributeBitangent)
      Model.vertexDescriptor = mdlMesh.vertexDescriptor
      mtkMeshes.append(try! MTKMesh(mesh: mdlMesh, device: Renderer.device))
    }

    meshes = zip(mdlMeshes, mtkMeshes).map {
      Mesh(mdlMesh: $0.0, mtkMesh: $0.1,
           startTime: asset.startTime,
           endTime: asset.endTime)
    }
    samplerState = Model.buildSamplerState()
    
    // load animations
    let assetAnimations = asset.animations.objects.compactMap {
      $0 as? MDLPackedJointAnimation
    }
    let animations: [String: AnimationClip] = Dictionary(uniqueKeysWithValues: assetAnimations.map {
      let name = URL(fileURLWithPath: $0.name).lastPathComponent
      return (name, AnimationComponent.load(animation: $0))
    })
    self.animations = animations
    debugBoundingBox = DebugBoundingBox(boundingBox: asset.boundingBox)

    super.init()
    self.boundingBox = asset.boundingBox
    self.name = name
  }
  
  private static func buildSamplerState() -> MTLSamplerState? {
    let descriptor = MTLSamplerDescriptor()
    descriptor.sAddressMode = .repeat
    descriptor.tAddressMode = .repeat
    descriptor.mipFilter = .linear
    descriptor.maxAnisotropy = 8
    let samplerState =
      Renderer.device.makeSamplerState(descriptor: descriptor)
    return samplerState
  }
  
  override func update(deltaTime: Float) {
    if animationPaused == false {
      currentTime += deltaTime
    }
    
    for mesh in meshes {
      if let animationClip = currentAnimation {
        mesh.skeleton?.updatePose(animationClip: animationClip,
                                  at: currentTime)
        mesh.transform?.currentTransform = .identity()
      } else {
        if let animationClip = currentAnimation {
          mesh.skeleton?.updatePose(animationClip: animationClip,
                                    at: currentTime)
        }
        mesh.transform?.setCurrentTransform(at: currentTime)
      }
    }
  }

}

extension Model: Renderable {
  
  // Perform draw call
  func render(renderEncoder: MTLRenderCommandEncoder, submesh: Submesh) {
    let mtkSubmesh = submesh.mtkSubmesh
    renderEncoder.drawIndexedPrimitives(type: .triangle,
                                        indexCount: mtkSubmesh.indexCount,
                                        indexType: mtkSubmesh.indexType,
                                        indexBuffer: mtkSubmesh.indexBuffer.buffer,
                                        indexBufferOffset: mtkSubmesh.indexBuffer.offset)
  }
  
  func render(renderEncoder: MTLRenderCommandEncoder, uniforms vertex: Uniforms,
              fragmentUniforms fragment: FragmentUniforms) {
    var uniforms = vertex
    
    var fragmentUniforms = fragment
    fragmentUniforms.tiling = tiling
    renderEncoder.setFragmentBytes(&fragmentUniforms,
                                   length: MemoryLayout<FragmentUniforms>.stride,
                                   index: Int(BufferIndexFragmentUniforms.rawValue))
    renderEncoder.setFragmentSamplerState(samplerState, index: 0)

    for mesh in meshes {
      if let paletteBuffer = mesh.skeleton?.jointMatrixPaletteBuffer {
        renderEncoder.setVertexBuffer(paletteBuffer, offset: 0, index: 22)
      }
      
      let currentLocalTransform =
        mesh.transform?.currentTransform ?? .identity()
      uniforms.modelMatrix = modelMatrix * currentLocalTransform

      uniforms.normalMatrix = uniforms.modelMatrix.upperLeft
      renderEncoder.setVertexBytes(&uniforms,
                                   length: MemoryLayout<Uniforms>.stride,
                                   index: Int(BufferIndexUniforms.rawValue))

      for (index, vertexBuffer) in mesh.mtkMesh.vertexBuffers.enumerated() {
        renderEncoder.setVertexBuffer(vertexBuffer.buffer,
                                      offset: 0, index: index)
      }
      
      for submesh in mesh.submeshes {
        // textures
        renderEncoder.setFragmentTexture(submesh.textures.baseColor,
                                         index: Int(BaseColorTexture.rawValue))
        renderEncoder.setFragmentTexture(submesh.textures.normal,
                                         index: Int(NormalTexture.rawValue))
        renderEncoder.setFragmentTexture(submesh.textures.roughness,
                                         index: Int(RoughnessTexture.rawValue))
        renderEncoder.setFragmentTexture(submesh.textures.metallic,
                                         index: Int(MetallicTexture.rawValue))
        renderEncoder.setFragmentTexture(submesh.textures.ao,
                                         index: Int(AOTexture.rawValue))

        renderEncoder.setRenderPipelineState(submesh.pipelineState)
        var material = submesh.material
        renderEncoder.setFragmentBytes(&material,
                                       length: MemoryLayout<Material>.stride,
                                       index: Int(BufferIndexMaterials.rawValue))
        
        // perform draw call
        render(renderEncoder: renderEncoder, submesh: submesh)
      }
      if debugRenderBoundingBox {
        debugBoundingBox.render(renderEncoder: renderEncoder, uniforms: uniforms)
      }
    }
  }
}

// MARK: - Animation control

extension Model {
  func runAnimation(name: String) {
    currentAnimation = animations[name]
    if currentAnimation != nil {
      animationPaused = false
      currentTime = 0
    }
  }
  
  func pauseAnimation() {
    animationPaused = true
  }
  
  func resumeAnimation() {
    animationPaused = false
  }
  
  func stopAnimation() {
    animationPaused = true
    currentAnimation = nil
  }

}


