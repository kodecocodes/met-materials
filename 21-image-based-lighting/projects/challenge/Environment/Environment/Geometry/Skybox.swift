///// Copyright (c) 2023 Kodeco Inc.
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

struct Skybox {
  let mesh: MTKMesh
  var skyTexture: MTLTexture?
  let pipelineState: MTLRenderPipelineState
  let depthStencilState: MTLDepthStencilState?

  struct SkySettings {
    var turbidity: Float = 0.15
    var sunElevation: Float = 0.56
    var upperAtmosphereScattering: Float = 0.66
    var groundAlbedo: Float = 0.8
  }
  var skySettings = SkySettings()
  var diffuseTexture: MTLTexture?
  var brdfLut: MTLTexture?

  init(textureName: String?) {
    let allocator =
      MTKMeshBufferAllocator(device: Renderer.device)
    let cube = MDLMesh(
      boxWithExtent: [1, 1, 1],
      segments: [1, 1, 1],
      inwardNormals: true,
      geometryType: .triangles,
      allocator: allocator)
    do {
      mesh = try MTKMesh(
        mesh: cube, device: Renderer.device)
    } catch {
      fatalError("failed to create skybox mesh")
    }
    pipelineState = PipelineStates.createSkyboxPSO(
      vertexDescriptor: MTKMetalVertexDescriptorFromModelIO(
        cube.vertexDescriptor))
    depthStencilState = Self.buildDepthStencilState()
    if let textureName {
      skyTexture = TextureController.loadCubeTexture(
        imageName: textureName)
      diffuseTexture =
        TextureController.loadCubeTexture(
          imageName: "irradiance.png")
    } else {
      skyTexture = loadGeneratedSkyboxTexture(dimensions: [256, 256])
    }
    brdfLut = Renderer.buildBRDF()
  }

  func loadGeneratedSkyboxTexture(dimensions: SIMD2<Int32>)
    -> MTLTexture? {
    var texture: MTLTexture?
    let skyTexture = MDLSkyCubeTexture(
      name: "sky",
      channelEncoding: .float16,
      textureDimensions: dimensions,
      turbidity: skySettings.turbidity,
      sunElevation: skySettings.sunElevation,
      upperAtmosphereScattering:
        skySettings.upperAtmosphereScattering,
      groundAlbedo: skySettings.groundAlbedo)
    do {
      let textureLoader =
        MTKTextureLoader(device: Renderer.device)
      texture = try textureLoader.newTexture(
        texture: skyTexture,
        options: nil)
    } catch {
      print(error.localizedDescription)
    }
    return texture
  }

  static func buildDepthStencilState() -> MTLDepthStencilState? {
    let descriptor = MTLDepthStencilDescriptor()
    descriptor.depthCompareFunction = .lessEqual
    descriptor.isDepthWriteEnabled = true
    return Renderer.device.makeDepthStencilState(
      descriptor: descriptor)
  }

  func update(encoder: MTLRenderCommandEncoder) {
    encoder.setFragmentTexture(
      skyTexture,
      index: SkyboxTexture.index)
    encoder.setFragmentTexture(
      diffuseTexture,
      index: SkyboxDiffuseTexture.index)
    encoder.setFragmentTexture(
      brdfLut,
      index: BRDFLutTexture.index)
  }

  func render(
    encoder: MTLRenderCommandEncoder,
    uniforms: Uniforms
  ) {
    encoder.pushDebugGroup("Skybox")
    encoder.setRenderPipelineState(pipelineState)
    encoder.setDepthStencilState(depthStencilState)
    encoder.setVertexBuffer(
      mesh.vertexBuffers[0].buffer,
      offset: 0,
      index: 0)
    var uniforms = uniforms
    uniforms.viewMatrix.columns.3 = [0, 0, 0, 1]
    encoder.setVertexBytes(
      &uniforms,
      length: MemoryLayout<Uniforms>.stride,
      index: UniformsBuffer.index)
    let submesh = mesh.submeshes[0]

    encoder.setFragmentTexture(
      skyTexture,
      index: SkyboxTexture.index)

    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: submesh.indexCount,
      indexType: submesh.indexType,
      indexBuffer: submesh.indexBuffer.buffer,
      indexBufferOffset: 0)
    encoder.popDebugGroup()
  }
}
