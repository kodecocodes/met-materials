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

struct GrassRenderPass: RenderPass {
  let label = "Grass Render Pass"
  var descriptor: MTLRenderPassDescriptor?

  var pipelineState: MTLRenderPipelineState
  let depthStencilState: MTLDepthStencilState?

  let grassSettings = GrassSettings(
    maxDistance: 30,
    bladeVertices: 3,
    gridSize: 25,
    tileSize: 2)

  init() {
    pipelineState = PipelineStates.createGrassPSO()
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
      let renderEncoder =
        commandBuffer.makeRenderCommandEncoder(
          descriptor: descriptor) else { return }
    renderEncoder.label = label
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setRenderPipelineState(pipelineState)

    var grassUniforms = GrassUniforms()
    let viewProjectionMatrix =
      scene.camera.projectionMatrix * scene.camera.viewMatrix
    grassUniforms.viewProjectionMatrix = viewProjectionMatrix
    grassUniforms.cameraPosition = scene.camera.position
    grassUniforms.cameraForward = scene.camera.forwardVector
    renderEncoder.setObjectBytes(
      &grassUniforms,
      length: MemoryLayout<GrassUniforms>.stride,
      index: GrassUniformsBuffer.index)

    renderEncoder.setMeshBytes(
      &grassUniforms,
      length: MemoryLayout<GrassUniforms>.stride,
      index: GrassUniformsBuffer.index)

    var grassSettings = grassSettings
    renderEncoder.setObjectBytes(
      &grassSettings,
      length: MemoryLayout<GrassSettings>.stride,
      index: GrassSettingsBuffer.index)

    let threadgroupsPerGrid = MTLSize(
      width: Int(grassSettings.gridSize),
      height: 1,
      depth: Int(grassSettings.gridSize))
    let threadsPerTile =
      MTLSize(width: 1, height: 1, depth: 1)
    let threadsPerBlade = MTLSize(
      width: Int(grassSettings.bladeVertices),
      height: 1,
      depth: 1)
    renderEncoder.drawMeshThreadgroups(
      threadgroupsPerGrid,
      threadsPerObjectThreadgroup: threadsPerTile,
      threadsPerMeshThreadgroup: threadsPerBlade)

    renderEncoder.endEncoding()
  }
}
