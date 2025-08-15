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

struct GrassMeshRenderPass: RenderPass {
  let label = "Grass Mesh Render Pass"
  var descriptor: MTLRenderPassDescriptor?
  var pipelineState: MTLRenderPipelineState
  let depthStencilState: MTLDepthStencilState?
  // Grass-specific parameters
  let terrainSize: float2 = [3, 3] // width and depth of tiles - 2500 tiles.
  let tileSize: Float = 2.0         // Size of each grass tile

  let grass = GrassTile()

  init(view: MTKView) {
    pipelineState = PipelineStates.grassMeshPSO()
    depthStencilState = Self.buildDepthStencilState()
  }

  mutating func resize(view: MTKView, size: CGSize) {
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
      cameraPosition: float4(scene.camera.position.x, scene.camera.position.y, scene.camera.position.z, 1),
      maxDistance: grass.maxDistance,
      maxBladesPerTile: UInt32(grass.maxBladesPerTile),
      tileSize: grass.tileSize
    )

    renderEncoder.setObjectBytes(
      &objectUniforms,
      length: MemoryLayout<ObjectShaderUniforms>.stride,
      index: 0
    )

    // Set uniforms for mesh shader
    var meshUniforms = MeshShaderUniforms(
      viewProjectionMatrix: uniforms.projectionMatrix * uniforms.viewMatrix,
      cameraPosition: float4(scene.camera.position.x, scene.camera.position.y, scene.camera.position.z, 1),
      bladeHeight: 1,
      bladeWidth: 0.2
    )
    
    print(meshUniforms)
    renderEncoder.setMeshBytes(
      &meshUniforms,
      length: MemoryLayout<MeshShaderUniforms>.stride,
      index: 0
    )
    // Calculate grid dimensions based on terrain and tile size
    let tilesPerSide = Int(terrainSize.x)

    // Draw mesh threadgroups - this replaces traditional draw calls
    renderEncoder.drawMeshThreadgroups(
      MTLSize(width: tilesPerSide, height: 1, depth: tilesPerSide),
      threadsPerObjectThreadgroup: MTLSize(width: 1, height: 1, depth: 1),
      threadsPerMeshThreadgroup: MTLSize(
        width: Int(GrassThreadsPerMeshThreadgroup), height: 1, depth: 1)  // 32 threads per grass blade
    )
    renderEncoder.endEncoding()
  }
}

// MARK: - Uniform Structures


struct ObjectShaderUniforms {
  var viewMatrix: simd_float4x4
  var cameraPosition: simd_float4
  var maxDistance: Float
  var maxBladesPerTile: UInt32
  var tileSize: Float
}

struct MeshShaderUniforms {
  var viewProjectionMatrix: simd_float4x4
  var cameraPosition: simd_float4
  var bladeHeight: Float
  var bladeWidth: Float
}

struct GrassPayload {
  var bladePositions = [simd_float3](repeating: .zero, count: 64)
  var bladeCount: UInt32
}
