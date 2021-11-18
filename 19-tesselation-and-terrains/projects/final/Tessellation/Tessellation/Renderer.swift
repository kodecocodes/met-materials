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
import MetalPerformanceShaders

class Renderer: NSObject {
  
  static var device: MTLDevice!
  static var commandQueue: MTLCommandQueue!
  static var colorPixelFormat: MTLPixelFormat!
  static var library: MTLLibrary?
  static let maxTessellation: Int = {
    #if os(macOS)
    return 64
    #else
    return 16
    #endif
  } ()
  
  let patches = (horizontal: 6, vertical: 6)
  var patchCount: Int {
    return patches.horizontal * patches.vertical
  }
  var terrain = Terrain(size: [8, 8], height: 1,
                        maxTessellation: UInt32(Renderer.maxTessellation))
  
  let heightMap: MTLTexture
  
  var depthStencilState: MTLDepthStencilState
  var renderPipelineState: MTLRenderPipelineState
  var wireframe = true

  var edgeFactors: [Float] = [4]
  var insideFactors: [Float] = [4]
  
  lazy var tessellationFactorsBuffer: MTLBuffer? = {
    // 1
    let count = patchCount * (4 + 2)
    // 2
    let size = count * MemoryLayout<Float>.size / 2
    return Renderer.device.makeBuffer(length: size,
                                      options: .storageModePrivate)
  }()
  
  var controlPointsBuffer: MTLBuffer?
  var tessellationPipelineState: MTLComputePipelineState
  
  let terrainSlope: MTLTexture
  let cliffTexture: MTLTexture
  let snowTexture: MTLTexture
  let grassTexture: MTLTexture
  
  // model transform
  var position = float3([0, 0, 0])
  var rotation = float3(Float(-20).degreesToRadians, 0, 0)
  var modelMatrix: float4x4 {
    let translationMatrix = float4x4(translation: position)
    let rotationMatrix = float4x4(rotation: rotation)
    return translationMatrix * rotationMatrix
  }

  init(metalView: MTKView) {
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("GPU not available")
    }
    metalView.depthStencilPixelFormat = .depth32Float
    metalView.device = device
    Renderer.device = device
    Renderer.commandQueue = device.makeCommandQueue()!
    Renderer.colorPixelFormat = metalView.colorPixelFormat
    Renderer.library = device.makeDefaultLibrary()
    
    renderPipelineState = Renderer.buildRenderPipelineState()
    depthStencilState = Renderer.buildDepthStencilState()
    tessellationPipelineState = Renderer.buildComputePipelineState()
    
    do {
      heightMap = try Renderer.loadTexture(imageName: "mountain")
      cliffTexture = try Renderer.loadTexture(imageName: "cliff-color")
      snowTexture = try Renderer.loadTexture(imageName: "snow-color")
      grassTexture = try Renderer.loadTexture(imageName: "grass-color")
    } catch {
      fatalError(error.localizedDescription)
    }
    terrainSlope = Renderer.heightToSlope(source: heightMap)
    super.init()
    metalView.clearColor = MTLClearColor(red: 1, green: 1,
                                         blue: 1, alpha: 1)
    metalView.delegate = self
    let controlPoints = createControlPoints(patches: patches,
                                            size: (width: terrain.size.x,
                                                   height: terrain.size.y))
    controlPointsBuffer = Renderer.device.makeBuffer(bytes: controlPoints,
                                                     length: MemoryLayout<float3>.stride * controlPoints.count)
  }
  
  static func heightToSlope(source: MTLTexture) -> MTLTexture {
    let descriptor =
      MTLTextureDescriptor.texture2DDescriptor(pixelFormat:
        source.pixelFormat,
                                               width: source.width,
                                               height: source.height,
                                               mipmapped: false)
    descriptor.usage = [.shaderWrite, .shaderRead]
    guard let destination = Renderer.device.makeTexture(descriptor: descriptor),
      let commandBuffer = Renderer.commandQueue.makeCommandBuffer()
      else {
        fatalError()
    }
    let shader = MPSImageSobel(device: Renderer.device)
    shader.encode(commandBuffer: commandBuffer,
                  sourceTexture: source,
                  destinationTexture: destination)
    commandBuffer.commit()
    return destination
  }
  
  static func buildDepthStencilState() -> MTLDepthStencilState {
    let descriptor = MTLDepthStencilDescriptor()
    descriptor.depthCompareFunction = .less
    descriptor.isDepthWriteEnabled = true
    return Renderer.device.makeDepthStencilState(descriptor: descriptor)!
  }
  
  static func buildRenderPipelineState() -> MTLRenderPipelineState {
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    descriptor.depthAttachmentPixelFormat = .depth32Float

    let vertexFunction = Renderer.library?.makeFunction(name: "vertex_main")
    let fragmentFunction = Renderer.library?.makeFunction(name: "fragment_main")
    descriptor.vertexFunction = vertexFunction
    descriptor.fragmentFunction = fragmentFunction
    
    let vertexDescriptor = MTLVertexDescriptor()
    vertexDescriptor.attributes[0].format = .float3
    vertexDescriptor.attributes[0].offset = 0
    vertexDescriptor.attributes[0].bufferIndex = 0
    
    vertexDescriptor.layouts[0].stride = MemoryLayout<float3>.stride
    vertexDescriptor.layouts[0].stepFunction = .perPatchControlPoint
    descriptor.vertexDescriptor = vertexDescriptor
    
    descriptor.tessellationFactorStepFunction = .perPatch
    descriptor.maxTessellationFactor = Renderer.maxTessellation
    descriptor.tessellationPartitionMode = .pow2
    
    return try! device.makeRenderPipelineState(descriptor: descriptor)
  }
  
  static func buildComputePipelineState() -> MTLComputePipelineState {
    guard let kernelFunction =
      Renderer.library?.makeFunction(name: "tessellation_main") else {
        fatalError("Tessellation shader function not found")
    }
    return try!
      Renderer.device.makeComputePipelineState(function: kernelFunction)
  }
}

extension Renderer: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
  }
  
  func draw(in view: MTKView) {
    guard let descriptor = view.currentRenderPassDescriptor,
      let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
      let drawable =  view.currentDrawable
      else {
        return
    }
    // uniforms
    let projectionMatrix = float4x4(projectionFov: 1.2, near: 0.01, far: 100,
                                    aspect: Float(view.bounds.width/view.bounds.height))
    let viewMatrix = float4x4(translation: [0, 0, -1.8])
    var mvp = projectionMatrix * viewMatrix.inverse * modelMatrix

    
    // tessellation pass
    let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
    computeEncoder.setComputePipelineState(tessellationPipelineState)
    computeEncoder.setBytes(&edgeFactors,
                            length: MemoryLayout<Float>.size * edgeFactors.count,
                            index: 0)
    computeEncoder.setBytes(&insideFactors,
                            length: MemoryLayout<Float>.size * insideFactors.count,
                            index: 1)
    computeEncoder.setBuffer(tessellationFactorsBuffer, offset: 0, index: 2)
    let width = min(patchCount,
                    tessellationPipelineState.threadExecutionWidth)
    var cameraPosition = viewMatrix.columns.3
    computeEncoder.setBytes(&cameraPosition,
                            length: MemoryLayout<float4>.stride,
                            index: 3)
    var matrix = modelMatrix
    computeEncoder.setBytes(&matrix,
                            length: MemoryLayout<float4x4>.stride,
                            index: 4)
    computeEncoder.setBuffer(controlPointsBuffer, offset: 0, index: 5)
    computeEncoder.setBytes(&terrain,
                            length: MemoryLayout<Terrain>.stride,
                            index: 6)
    
    computeEncoder.dispatchThreadgroups(MTLSizeMake(patchCount, 1, 1),
                                        threadsPerThreadgroup: MTLSizeMake(width, 1, 1))
    computeEncoder.endEncoding()
    
    
    // render
    let renderEncoder =
      commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setVertexBytes(&mvp, length: MemoryLayout<float4x4>.stride, index: 1)
    renderEncoder.setRenderPipelineState(renderPipelineState)
    renderEncoder.setVertexBuffer(controlPointsBuffer, offset: 0, index: 0)
    
    let fillmode: MTLTriangleFillMode = wireframe ? .lines : .fill
    renderEncoder.setTriangleFillMode(fillmode)

    renderEncoder.setTessellationFactorBuffer(tessellationFactorsBuffer,
                                              offset: 0,
                                              instanceStride: 0)
    
    renderEncoder.setVertexTexture(heightMap, index: 0)
    renderEncoder.setVertexBytes(&terrain,
                                 length: MemoryLayout<Terrain>.stride, index: 6)
    
    renderEncoder.setFragmentTexture(cliffTexture, index: 1)
    renderEncoder.setFragmentTexture(snowTexture, index: 2)
    renderEncoder.setFragmentTexture(grassTexture, index: 3)
    
    // draw
    renderEncoder.drawPatches(numberOfPatchControlPoints: 4,
                              patchStart: 0, patchCount: patchCount,
                              patchIndexBuffer: nil,
                              patchIndexBufferOffset: 0,
                              instanceCount: 1, baseInstance: 0)
    
    renderEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}


