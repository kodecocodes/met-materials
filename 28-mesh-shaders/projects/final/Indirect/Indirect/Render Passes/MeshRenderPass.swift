///// Copyright (c) 2025 Kodeco Inc.
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
/*
struct GrassMeshRenderPassOld: RenderPass {
  let label = "Grass Mesh Render Pass"
  var descriptor: MTLRenderPassDescriptor?
  var pipelineState: MTLRenderPipelineState
  let depthStencilState: MTLDepthStencilState?
  // Grass-specific parameters
  let grassUniforms: GrassUniforms
  let terrainSize: Float = 100.0    // Total terrain size
  let tileSize: Float = 2.0         // Size of each grass tile
  init(view: MTKView) {
    pipelineState = Self.createGrassMeshPipelineState(view: view)
    depthStencilState = Self.buildDepthStencilState()
    
    // Initialize grass parameters
    grassUniforms = GrassUniforms(
      maxDistance: 50.0,
      maxBladesPerTile: 25,
      tileSize: 2.0,
      bladeHeight: 1.5,
      bladeWidth: 0.1,
      time: 0.0
    )
  }
  
  mutating func resize(view: MTKView, size: CGSize) {
    // Handle any resize-specific updates if needed
  }
  
  func draw(
    commandBuffer: MTLCommandBuffer,
    scene: GameScene,
    uniforms: Uniforms
  ) {
    guard let descriptor = descriptor,
          let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
    else { return }
    
    renderEncoder.label = label
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setRenderPipelineState(pipelineState)
    
    // Set uniforms for object shader
    var objectUniforms = ObjectShaderUniforms(
      viewMatrix: uniforms.viewMatrix,
      cameraPosition: scene.camera.position,
      maxDistance: grassUniforms.maxDistance,
      maxBladesPerTile: grassUniforms.maxBladesPerTile,
      tileSize: grassUniforms.tileSize
    )
    
    renderEncoder.setObjectBytes(
      &objectUniforms,
      length: MemoryLayout<ObjectShaderUniforms>.stride,
      index: 0
    )
    
    // Set uniforms for mesh shader
    var meshUniforms = MeshShaderUniforms(
      viewProjectionMatrix: uniforms.projectionMatrix * uniforms.viewMatrix,
      time: grassUniforms.time,
      bladeHeight: grassUniforms.bladeHeight,
      bladeWidth: grassUniforms.bladeWidth
    )
    
    renderEncoder.setMeshBytes(
      &meshUniforms,
      length: MemoryLayout<MeshShaderUniforms>.stride,
      index: 0
    )
    
    // Calculate grid dimensions based on terrain and tile size
    let tilesPerSide = Int(ceil(terrainSize / grassUniforms.tileSize))
    
    // Draw mesh threadgroups - this replaces traditional draw calls
    renderEncoder.drawMeshThreadgroups(
      MTLSize(width: tilesPerSide, height: 1, depth: tilesPerSide),
      threadsPerObjectThreadgroup: MTLSize(width: 1, height: 1, depth: 1),
      threadsPerMeshThreadgroup: MTLSize(width: 32, height: 1, depth: 1)  // 32 threads per grass blade
    )
    
    renderEncoder.endEncoding()
  }
  
  // MARK: - Pipeline State Creation
  
  static func createGrassMeshPipelineState(view: MTKView) -> MTLRenderPipelineState {
    let library = Renderer.library
    
    let descriptor = MTLMeshRenderPipelineDescriptor()
    
    // Set the shader functions
    descriptor.objectFunction = library?.makeFunction(name: "grassObjectShader")
    descriptor.meshFunction = library?.makeFunction(name: "grassMeshShader")
    descriptor.fragmentFunction = library?.makeFunction(name: "grassFragmentShader") // You'll need this
    
    // Set render target format
    descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
    descriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
    
    // Set payload size (16KB max)
    descriptor.payloadMemoryLength = MemoryLayout<GrassPayload>.stride
    
    // Set thread group sizes
    descriptor.maxTotalThreadsPerObjectThreadgroup = 1
    descriptor.maxTotalThreadsPerMeshThreadgroup = 32
    
    // Enable alpha blending if desired
    descriptor.colorAttachments[0].isBlendingEnabled = true
    descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
    descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
    
    do {
      let (pipelineState, _) = try Renderer.device.makeRenderPipelineState(
        descriptor: descriptor,
        options: MTLPipelineOption())
      return pipelineState
    } catch {
      fatalError("Unable to create grass mesh pipeline state: \(error)")
    }
  }
}
*/
