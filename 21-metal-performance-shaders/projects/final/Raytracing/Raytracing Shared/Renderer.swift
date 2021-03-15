//
/**
 * Copyright (c) 2018 Razeware LLC
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
import MetalPerformanceShaders

typealias float2 = SIMD2<Float>
typealias float3 = SIMD3<Float>

class Renderer: NSObject {
  var device: MTLDevice!
  var commandQueue: MTLCommandQueue!
  var library: MTLLibrary!
  
  var renderPipeline: MTLRenderPipelineState!
  
  var rayPipeline: MTLComputePipelineState!
  var rayBuffer: MTLBuffer!
  var shadowRayBuffer: MTLBuffer!
  
  var shadePipelineState: MTLComputePipelineState!
  
  var accumulatePipeline: MTLComputePipelineState!
  var accumulationTarget: MTLTexture!
  var accelerationStructure: MPSTriangleAccelerationStructure!
  var shadowPipeline: MTLComputePipelineState!
  
  var vertexPositionBuffer: MTLBuffer!
  var vertexNormalBuffer: MTLBuffer!
  var vertexColorBuffer: MTLBuffer!
  var indexBuffer: MTLBuffer!
  var uniformBuffer: MTLBuffer!
  var randomBuffer: MTLBuffer!
  
  var intersectionBuffer: MTLBuffer!
  let intersectionStride =
    MemoryLayout<MPSIntersectionDistancePrimitiveIndexCoordinates>.stride
  
  var intersector: MPSRayIntersector!
  let rayStride =
    MemoryLayout<MPSRayOriginMinDistanceDirectionMaxDistance>.stride
      + MemoryLayout<float3>.stride
  
  let maxFramesInFlight = 3
  let alignedUniformsSize = (MemoryLayout<Uniforms>.size + 255) & ~255
  var semaphore: DispatchSemaphore!
  var size = CGSize.zero
  var randomBufferOffset = 0
  var uniformBufferOffset = 0
  var uniformBufferIndex = 0
  var frameIndex: uint = 0
  
  var renderTarget: MTLTexture!
  
  lazy var vertexDescriptor: MDLVertexDescriptor = {
    let vertexDescriptor = MDLVertexDescriptor()
    vertexDescriptor.attributes[0] =
      MDLVertexAttribute(name: MDLVertexAttributePosition,
                         format: .float3,
                         offset: 0, bufferIndex: 0)
    vertexDescriptor.attributes[1] =
      MDLVertexAttribute(name: MDLVertexAttributeNormal,
                         format: .float3,
                         offset: 0, bufferIndex: 1)
    vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<float3>.stride)
    vertexDescriptor.layouts[1] = MDLVertexBufferLayout(stride: MemoryLayout<float3>.stride)
    return vertexDescriptor
  }()
  
  var vertices: [float3] = []
  var normals: [float3] = []
  var colors: [float3] = []
  
  init(metalView: MTKView) {
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("GPU not available")
    }
    metalView.device = device
    metalView.colorPixelFormat = .rgba16Float
    metalView.sampleCount = 1
    metalView.drawableSize = metalView.frame.size
    
    self.device = device
    commandQueue = device.makeCommandQueue()!
    library = device.makeDefaultLibrary()
    
    
    super.init()
    metalView.delegate = self
    mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
    semaphore = DispatchSemaphore.init(value: maxFramesInFlight)
    buildPipelines(view: metalView)
    createScene()
    createBuffers()
    buildIntersector()
    buildAccelerationStructure()
  }
  
  func buildAccelerationStructure() {
    accelerationStructure =
      MPSTriangleAccelerationStructure(device: device)
    accelerationStructure?.vertexBuffer = vertexPositionBuffer
    accelerationStructure?.triangleCount = vertices.count / 3
    accelerationStructure?.rebuild()
  }
  
  func buildIntersector() {
    intersector = MPSRayIntersector(device: device)
    intersector?.rayDataType = .originMinDistanceDirectionMaxDistance
    intersector?.rayStride = rayStride
  }
  
  func buildPipelines(view: MTKView) {
    let vertexFunction = library.makeFunction(name: "vertexShader")
    let fragmentFunction = library.makeFunction(name: "fragmentShader")
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.sampleCount = view.sampleCount
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
    let computeDescriptor = MTLComputePipelineDescriptor()
    computeDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
    
    do {
      computeDescriptor.computeFunction = library.makeFunction(
        name: "shadowKernel")
      shadowPipeline = try device.makeComputePipelineState(
        descriptor: computeDescriptor,
        options: [],
        reflection: nil)
      
      computeDescriptor.computeFunction = library.makeFunction(
        name: "shadeKernel")
      shadePipelineState = try device.makeComputePipelineState(
        descriptor: computeDescriptor,
        options: [],
        reflection: nil)
      
      computeDescriptor.computeFunction = library.makeFunction(
        name: "accumulateKernel")
      accumulatePipeline = try device.makeComputePipelineState(
        descriptor: computeDescriptor,
        options: [],
        reflection: nil)
      
      computeDescriptor.computeFunction = library.makeFunction(
        name: "primaryRays")
      rayPipeline = try device.makeComputePipelineState(
        descriptor: computeDescriptor,
        options: [],
        reflection: nil)
      
      renderPipeline = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    } catch {
      print(error.localizedDescription)
    }
  }
  
  func createScene() {
    loadAsset(name: "train", position: [-0.3, 0, 0.4], scale: 0.5)
    loadAsset(name: "treefir", position: [0.5, 0, -0.2], scale: 0.7)
    loadAsset(name: "plane", position: [0, 0, 0], scale: 10)
    loadAsset(name: "sphere", position: [-1.9, 0.0, 0.3], scale: 1)
    loadAsset(name: "sphere", position: [2.9, 0.0, -0.5], scale: 2)
    loadAsset(name: "plane-back", position: [0, 0, -1.5], scale: 10)
  }
  
  
  func createBuffers() {
    let uniformBufferSize = alignedUniformsSize * maxFramesInFlight

    let options: MTLResourceOptions = {
      #if os(iOS)
      return .storageModeShared
      #else
      return .storageModeManaged
      #endif
    } ()
    
    uniformBuffer = device.makeBuffer(length: uniformBufferSize, options: options)
    randomBuffer = device.makeBuffer(length: 256 * MemoryLayout<float2>.stride * maxFramesInFlight, options: options)
    vertexPositionBuffer = device.makeBuffer(bytes: &vertices, length: vertices.count * MemoryLayout<float3>.stride, options: options)
    vertexColorBuffer = device.makeBuffer(bytes: &colors, length: colors.count * MemoryLayout<float3>.stride, options: options)
    vertexNormalBuffer = device.makeBuffer(bytes: &normals, length: normals.count * MemoryLayout<float3>.stride, options: options)
  }
  
  func update() {
    updateUniforms()
    updateRandomBuffer()
    uniformBufferIndex = (uniformBufferIndex + 1) % maxFramesInFlight
  }
  
  func updateUniforms() {
    uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
    let pointer = uniformBuffer!.contents().advanced(by: uniformBufferOffset)
    let uniforms = pointer.bindMemory(to: Uniforms.self, capacity: 1)
    
    var camera = Camera()
    camera.position = float3(0.0, 1.0, 3.38)
    camera.forward = float3(0.0, 0.0, -1.0)
    camera.right = float3(1.0, 0.0, 0.0)
    camera.up = float3(0.0, 1.0, 0.0)
    
    let fieldOfView = 45.0 * (Float.pi / 180.0)
    let aspectRatio = Float(size.width) / Float(size.height)
    let imagePlaneHeight = tanf(fieldOfView / 2.0)
    let imagePlaneWidth = aspectRatio * imagePlaneHeight
    
    camera.right *= imagePlaneWidth
    camera.up *= imagePlaneHeight
    
    var light = AreaLight()
    light.position = float3(0.0, 1.98, 0.0)
    light.forward = float3(0.0, -1.0, 0.0)
    light.right = float3(0.25, 0.0, 0.0)
    light.up = float3(0.0, 0.0, 0.25)
    light.color = float3(4.0, 4.0, 4.0)
    
    uniforms.pointee.camera = camera
    uniforms.pointee.light = light
    
    uniforms.pointee.width = uint(size.width)
    uniforms.pointee.height = uint(size.height)
    uniforms.pointee.blocksWide = ((uniforms.pointee.width) + 15) / 16
    uniforms.pointee.frameIndex = frameIndex
    frameIndex += 1
    #if os(OSX)
    uniformBuffer?.didModifyRange(uniformBufferOffset..<(uniformBufferOffset + alignedUniformsSize))
    #endif
  }
  
  func updateRandomBuffer() {
    randomBufferOffset = 256 * MemoryLayout<float2>.stride * uniformBufferIndex
    let pointer = randomBuffer!.contents().advanced(by: randomBufferOffset)
    var random = pointer.bindMemory(to: float2.self, capacity: 256)
    for _ in 0..<256 {
      random.pointee = float2(Float(drand48()), Float(drand48()) )
      random = random.advanced(by: 1)
    }
    #if os(OSX)
    randomBuffer?.didModifyRange(randomBufferOffset..<(randomBufferOffset + 256 * MemoryLayout<float2>.stride))
    #endif
  }
}


extension Renderer: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    self.size = size
    frameIndex = 0
    let renderTargetDescriptor = MTLTextureDescriptor()
    renderTargetDescriptor.pixelFormat = .rgba32Float
    renderTargetDescriptor.textureType = .type2D
    renderTargetDescriptor.width = Int(size.width)
    renderTargetDescriptor.height = Int(size.height)
    renderTargetDescriptor.storageMode = .private
    renderTargetDescriptor.usage = [.shaderRead, .shaderWrite]
    renderTarget = device.makeTexture(descriptor: renderTargetDescriptor)
    
    let rayCount = Int(size.width * size.height)
    rayBuffer = device.makeBuffer(length: rayStride * rayCount,
                                  options: .storageModePrivate)
    shadowRayBuffer = device.makeBuffer(length: rayStride * rayCount,
                                        options: .storageModePrivate)
    
    accumulationTarget = device.makeTexture(
      descriptor: renderTargetDescriptor)
    
    intersectionBuffer = device.makeBuffer(
      length: intersectionStride * rayCount,
      options: .storageModePrivate)
  }
  
  func draw(in view: MTKView) {
    semaphore.wait()
    guard let commandBuffer = commandQueue.makeCommandBuffer() else {
      return
    }
    commandBuffer.addCompletedHandler { cb in
      self.semaphore.signal()
    }
    update()
    
    // MARK: generate rays
    let width = Int(size.width)
    let height = Int(size.height)
    let threadsPerGroup = MTLSizeMake(8, 8, 1)
    let threadGroups = MTLSizeMake((width + threadsPerGroup.width - 1)
      / threadsPerGroup.width,
                                   (height + threadsPerGroup.height - 1)
                                    / threadsPerGroup.height,
                                   1)
    var computeEncoder = commandBuffer.makeComputeCommandEncoder()
    computeEncoder?.label = "Generate Rays"
    computeEncoder?.setBuffer(uniformBuffer, offset: uniformBufferOffset,
                              index: 0)
    computeEncoder?.setBuffer(rayBuffer, offset: 0, index: 1)
    computeEncoder?.setBuffer(randomBuffer, offset: randomBufferOffset,
                              index: 2)
    computeEncoder?.setTexture(renderTarget, index: 0)
    computeEncoder?.setComputePipelineState(rayPipeline)
    computeEncoder?.dispatchThreadgroups(threadGroups,
                                         threadsPerThreadgroup: threadsPerGroup)
    computeEncoder?.endEncoding()
    
    for _ in 0..<3 {
      // MARK: generate intersections between rays and model triangles
      intersector?.intersectionDataType = .distancePrimitiveIndexCoordinates
      intersector?.encodeIntersection(
        commandBuffer: commandBuffer,
        intersectionType: .nearest,
        rayBuffer: rayBuffer,
        rayBufferOffset: 0,
        intersectionBuffer: intersectionBuffer,
        intersectionBufferOffset: 0,
        rayCount: width * height,
        accelerationStructure: accelerationStructure)
      
      // MARK: shading
      
      computeEncoder = commandBuffer.makeComputeCommandEncoder()
      computeEncoder?.label = "Shading"
      computeEncoder?.setBuffer(uniformBuffer, offset: uniformBufferOffset,
                                index: 0)
      computeEncoder?.setBuffer(rayBuffer, offset: 0, index: 1)
      computeEncoder?.setBuffer(shadowRayBuffer, offset: 0, index: 2)
      computeEncoder?.setBuffer(intersectionBuffer, offset: 0, index: 3)
      computeEncoder?.setBuffer(vertexColorBuffer, offset: 0, index: 4)
      computeEncoder?.setBuffer(vertexNormalBuffer, offset: 0, index: 5)
      computeEncoder?.setBuffer(randomBuffer, offset: randomBufferOffset,
                                index: 6)
      computeEncoder?.setTexture(renderTarget, index: 0)
      computeEncoder?.setComputePipelineState(shadePipelineState!)
      computeEncoder?.dispatchThreadgroups(
        threadGroups,
        threadsPerThreadgroup: threadsPerGroup)
      computeEncoder?.endEncoding()
      
      // MARK: shadows
      intersector?.label = "Shadows Intersector"
      intersector?.intersectionDataType = .distance
      intersector?.encodeIntersection(
        commandBuffer: commandBuffer,
        intersectionType: .any,
        rayBuffer: shadowRayBuffer,
        rayBufferOffset: 0,
        intersectionBuffer: intersectionBuffer,
        intersectionBufferOffset: 0,
        rayCount: width * height,
        accelerationStructure: accelerationStructure)
      
      computeEncoder = commandBuffer.makeComputeCommandEncoder()
      computeEncoder?.label = "Shadows"
      computeEncoder?.setBuffer(uniformBuffer, offset: uniformBufferOffset,
                                index: 0)
      computeEncoder?.setBuffer(shadowRayBuffer, offset: 0, index: 1)
      computeEncoder?.setBuffer(intersectionBuffer, offset: 0, index: 2)
      computeEncoder?.setTexture(renderTarget, index: 0)
      computeEncoder?.setComputePipelineState(shadowPipeline!)
      computeEncoder?.dispatchThreadgroups(
        threadGroups,
        threadsPerThreadgroup: threadsPerGroup)
      computeEncoder?.endEncoding()
      
      
    }
    // MARK: accumulation
    
    computeEncoder = commandBuffer.makeComputeCommandEncoder()
    computeEncoder?.label = "Accumulation"
    computeEncoder?.setBuffer(uniformBuffer, offset: uniformBufferOffset,
                              index: 0)
    computeEncoder?.setTexture(renderTarget, index: 0)
    computeEncoder?.setTexture(accumulationTarget, index: 1)
    computeEncoder?.setComputePipelineState(accumulatePipeline)
    computeEncoder?.dispatchThreadgroups(threadGroups,
                                         threadsPerThreadgroup: threadsPerGroup)
    computeEncoder?.endEncoding()
    
    guard let descriptor = view.currentRenderPassDescriptor,
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(
        descriptor: descriptor) else {
          return
    }
    renderEncoder.setRenderPipelineState(renderPipeline!)
    
    // MARK: draw call
    renderEncoder.setFragmentTexture(accumulationTarget, index: 0)
    renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    renderEncoder.endEncoding()
    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
