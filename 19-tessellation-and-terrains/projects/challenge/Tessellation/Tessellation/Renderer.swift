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
import MetalPerformanceShaders

// swiftlint:disable implicitly_unwrapped_optional

class Renderer: NSObject {
  static var device: MTLDevice!
  static var commandQueue: MTLCommandQueue!
  static var library: MTLLibrary!
  var options: Options

  let depthStencilState: MTLDepthStencilState?
  var pipelineState: MTLRenderPipelineState

  var timer: Float = 0
  var uniforms = Uniforms()
  var params = Params()

  let quad = Quad()
  var camera = ArcballCamera(distance: 2)

  let patches = (horizontal: 6, vertical: 6)
  lazy var terrain = Terrain(
    size: [8, 8],
    height: 1,
    maxTessellation: UInt32(Renderer.maxTessellation))

  var patchCount: Int {
    patches.horizontal * patches.vertical
  }
  var edgeFactors: [Float] = [4]
  var insideFactors: [Float] = [4]

  lazy var tessellationFactorsBuffer: MTLBuffer? = {
    let count = patchCount * (4 + 2)
    let size = count * MemoryLayout<Float>.size / 2
    return Renderer.device.makeBuffer(
      length: size,
      options: .storageModePrivate)
  }()
  var controlPointsBuffer: MTLBuffer?

  var tessellationPipelineState: MTLComputePipelineState

  static var maxTessellation: Int {
    device?.supportsFamily(.apple5) ?? false ? 64 : 16
  }

  let heightMap: MTLTexture!
  let cliffTexture: MTLTexture?
  let snowTexture: MTLTexture?
  let grassTexture: MTLTexture?
  let terrainSlope: MTLTexture

  // model transform
  var modelMatrix: float4x4 {
    let rotation = float3(Float(-20).degreesToRadians, 0, 0)
    return float4x4(rotation: rotation)
  }

  init(metalView: MTKView, options: Options) {
    guard
      let device = MTLCreateSystemDefaultDevice(),
      let commandQueue = device.makeCommandQueue() else {
        fatalError("GPU not available")
    }
    Renderer.device = device
    Renderer.commandQueue = commandQueue
    Renderer.library = device.makeDefaultLibrary()
    metalView.device = device

    pipelineState = PipelineStates.createRenderPSO(
      colorPixelFormat: metalView.colorPixelFormat)
    depthStencilState = Renderer.buildDepthStencilState()

    self.options = options

    tessellationPipelineState =
      PipelineStates.createComputePSO(function: "tessellation_main")
    heightMap = TextureController.loadTexture(name: "mountain")
    cliffTexture = TextureController.loadTexture(name: "cliff-color")
    snowTexture = TextureController.loadTexture(name: "snow-color")
    grassTexture = TextureController.loadTexture(name: "grass-color")
    terrainSlope = Renderer.heightToSlope(source: heightMap)

    super.init()
    metalView.clearColor = MTLClearColor(
      red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    metalView.depthStencilPixelFormat = .depth32Float
    metalView.delegate = self
    mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)

    let controlPoints = Quad.createControlPoints(
      patches: patches,
      size: (width: terrain.size.x, height: terrain.size.y))
    controlPointsBuffer =
      Renderer.device.makeBuffer(
        bytes: controlPoints,
        length: MemoryLayout<float3>.stride * controlPoints.count)
  }

  static func buildDepthStencilState() -> MTLDepthStencilState? {
    let descriptor = MTLDepthStencilDescriptor()
    descriptor.depthCompareFunction = .less
    descriptor.isDepthWriteEnabled = true
    return Renderer.device.makeDepthStencilState(
      descriptor: descriptor)
  }

  static func heightToSlope(source: MTLTexture) -> MTLTexture {
    let descriptor =
      MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: source.pixelFormat,
        width: source.width,
        height: source.height,
        mipmapped: false)
    descriptor.usage = [.shaderWrite, .shaderRead]
    guard let destination =
      Renderer.device.makeTexture(descriptor: descriptor),
      let commandBuffer = Renderer.commandQueue.makeCommandBuffer()
    else {
      fatalError("Error creating Sobel texture")
    }
    let shader = MPSImageSobel(device: Renderer.device)
    shader.encode(
      commandBuffer: commandBuffer,
      sourceTexture: source,
      destinationTexture: destination)
    commandBuffer.commit()
    return destination
  }
}

extension Renderer: MTKViewDelegate {
  func mtkView(
    _ view: MTKView,
    drawableSizeWillChange size: CGSize
  ) {
    camera.update(size: size)
    params.width = UInt32(size.width)
    params.height = UInt32(size.height)
  }

  func updateUniforms() {
    camera.update(deltaTime: 0.016)
    uniforms.projectionMatrix = camera.projectionMatrix
    uniforms.viewMatrix = camera.viewMatrix
    uniforms.modelMatrix = modelMatrix
    uniforms.mvp = uniforms.projectionMatrix * uniforms.viewMatrix
      * uniforms.modelMatrix
  }

  func tessellation(commandBuffer: MTLCommandBuffer) {
    guard let computeEncoder =
      commandBuffer.makeComputeCommandEncoder() else { return }
    computeEncoder.setComputePipelineState(
      tessellationPipelineState)
    computeEncoder.setBytes(
      &edgeFactors,
      length: MemoryLayout<Float>.size * edgeFactors.count,
      index: 0)
    computeEncoder.setBytes(
      &insideFactors,
      length: MemoryLayout<Float>.size * insideFactors.count,
      index: 1)
    computeEncoder.setBuffer(
      tessellationFactorsBuffer,
      offset: 0,
      index: 2)
    var cameraPosition = float4(camera.position, 0)
    computeEncoder.setBytes(
      &cameraPosition,
      length: MemoryLayout<float4>.stride,
      index: 3)
    var matrix = modelMatrix
    computeEncoder.setBytes(
      &matrix,
      length: MemoryLayout<float4x4>.stride,
      index: 4)
    computeEncoder.setBuffer(
      controlPointsBuffer,
      offset: 0,
      index: 5)
    computeEncoder.setBytes(
      &terrain,
      length: MemoryLayout<Terrain>.stride,
      index: 6)
    let width = min(
      patchCount,
      tessellationPipelineState.threadExecutionWidth)
    let gridSize =
      MTLSize(width: patchCount, height: 1, depth: 1)
    let threadsPerThreadgroup =
      MTLSize(width: width, height: 1, depth: 1)
    computeEncoder.dispatchThreadgroups(
      gridSize,
      threadsPerThreadgroup: threadsPerThreadgroup)
    computeEncoder.endEncoding()
  }

  func render(commandBuffer: MTLCommandBuffer, view: MTKView) {
    guard let descriptor = view.currentRenderPassDescriptor,
      let renderEncoder =
        commandBuffer.makeRenderCommandEncoder(
          descriptor: descriptor) else { return }
    renderEncoder.setDepthStencilState(depthStencilState)

    renderEncoder.setFragmentBytes(
      &params,
      length: MemoryLayout<Uniforms>.stride,
      index: BufferIndexParams.index)
    renderEncoder.setRenderPipelineState(pipelineState)

    renderEncoder.setVertexBytes(
      &uniforms,
      length: MemoryLayout<Uniforms>.stride,
      index: BufferIndexUniforms.index)

    // draw
    renderEncoder.setTessellationFactorBuffer(
      tessellationFactorsBuffer,
      offset: 0,
      instanceStride: 0)

    renderEncoder.setVertexBuffer(
      controlPointsBuffer,
      offset: 0,
      index: 0)

    let fillmode: MTLTriangleFillMode = options.isWireframe ? .lines : .fill
    renderEncoder.setTriangleFillMode(fillmode)

    renderEncoder.setVertexTexture(heightMap, index: 0)
    renderEncoder.setVertexBytes(
      &terrain,
      length: MemoryLayout<Terrain>.stride,
      index: 6)

    renderEncoder.setFragmentTexture(cliffTexture, index: 1)
    renderEncoder.setFragmentTexture(snowTexture, index: 2)
    renderEncoder.setFragmentTexture(grassTexture, index: 3)
    renderEncoder.setVertexTexture(terrainSlope, index: 4)

    renderEncoder.drawPatches(
      numberOfPatchControlPoints: 4,
      patchStart: 0,
      patchCount: patchCount,
      patchIndexBuffer: nil,
      patchIndexBufferOffset: 0,
      instanceCount: 1,
      baseInstance: 0)

    renderEncoder.endEncoding()
  }

  func draw(in view: MTKView) {
    guard
      let commandBuffer = Renderer.commandQueue.makeCommandBuffer() else {
        return
    }
    updateUniforms()

    tessellation(commandBuffer: commandBuffer)

    render(commandBuffer: commandBuffer, view: view)

    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}

// swiftlint:enable implicitly_unwrapped_optional
