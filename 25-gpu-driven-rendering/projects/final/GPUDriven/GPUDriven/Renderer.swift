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

class Renderer: NSObject {
  static var device: MTLDevice!
  static var commandQueue: MTLCommandQueue!
  static var library: MTLLibrary!

  var uniforms = Uniforms()
  var fragmentUniforms = FragmentUniforms()
  var modelParams = ModelParams()
  
  let depthStencilState: MTLDepthStencilState

  lazy var camera: Camera = {
    let camera = ArcballCamera()
    camera.distance = 4.3
    camera.target = [0, 1.2, 0]
    camera.rotation.x = Float(-10).degreesToRadians
    return camera
  }()
  
  // Array of Models allows for rendering multiple models
  var models: [Model] = []
  
  var uniformsBuffer: MTLBuffer!
  var fragmentUniformsBuffer: MTLBuffer!
  var modelParamsBuffer: MTLBuffer!
  
  var icb: MTLIndirectCommandBuffer!
  let icbPipelineState: MTLComputePipelineState
  let icbComputeFunction: MTLFunction
  var icbBuffer: MTLBuffer!
  var modelsBuffer: MTLBuffer!
  var drawArgumentsBuffer: MTLBuffer!
  
  init(metalView: MTKView) {
    guard
      let device = MTLCreateSystemDefaultDevice(),
      let commandQueue = device.makeCommandQueue() else {
        fatalError("GPU not available")
    }
    Renderer.device = device
    Renderer.commandQueue = commandQueue
    Renderer.library = device.makeDefaultLibrary()
    metalView.device = device
    metalView.depthStencilPixelFormat = .depth32Float
    
    depthStencilState = Renderer.buildDepthStencilState()!
    icbComputeFunction =
        Renderer.library.makeFunction(name: "encodeCommands")!
    icbPipelineState =
        Renderer.buildComputePipelineState(function: icbComputeFunction)
    
    super.init()
    metalView.clearColor = MTLClearColor(red: 0.7, green: 0.9,
                                         blue: 1.0, alpha: 1)
    metalView.delegate = self
    mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)

    // models
    let house = Model(name: "lowpoly-house.obj")
    house.rotation = [0, .pi/4, 0]
    models.append(house)
    let ground = Model(name: "plane.obj")
    ground.scale = [40, 40, 40]
    ground.tiling = 16
    models.append(ground)
    initialize()
    initializeCommands()
  }

  static func buildComputePipelineState(function: MTLFunction)
         -> MTLComputePipelineState {
    let computePipelineState: MTLComputePipelineState
    do {
      computePipelineState = try
            Renderer.device.makeComputePipelineState(function: function)
    } catch {
      fatalError(error.localizedDescription)
    }
    return computePipelineState
  }
  
  func initialize() {
    TextureController.heap = TextureController.buildHeap()
    models.forEach { model in
      model.initializeTextures()
    }
    
    var bufferLength = MemoryLayout<Uniforms>.stride
    uniformsBuffer =
        Renderer.device.makeBuffer(length: bufferLength, options: [])
    uniformsBuffer.label = "Uniforms"
    bufferLength = MemoryLayout<FragmentUniforms>.stride
    fragmentUniformsBuffer =
        Renderer.device.makeBuffer(length: bufferLength, options: [])
    fragmentUniformsBuffer.label = "Fragment Uniforms"
    bufferLength = models.count * MemoryLayout<ModelParams>.stride
    modelParamsBuffer =
        Renderer.device.makeBuffer(length: bufferLength, options: [])
    modelParamsBuffer.label = "Model Parameters"
  }
  
  func initializeCommands() {
    let icbDescriptor = MTLIndirectCommandBufferDescriptor()
    icbDescriptor.commandTypes = [.drawIndexed]
    icbDescriptor.inheritBuffers = false
    icbDescriptor.maxVertexBufferBindCount = 25
    icbDescriptor.maxFragmentBufferBindCount = 25
    icbDescriptor.inheritPipelineState = false
    
    guard let icb =
        Renderer.device.makeIndirectCommandBuffer(
            descriptor: icbDescriptor,
            maxCommandCount: models.count,
            options: []) else {
            fatalError()
      }
    self.icb = icb
    
    let icbEncoder = icbComputeFunction.makeArgumentEncoder(
                     bufferIndex: Int(BufferIndexICB.rawValue))
    icbBuffer = Renderer.device.makeBuffer(
                     length: icbEncoder.encodedLength,
                     options: [])
    icbEncoder.setArgumentBuffer(icbBuffer, offset: 0)
    icbEncoder.setIndirectCommandBuffer(icb, index: 0)
    
    var mBuffers: [MTLBuffer] = []
    var mBuffersLength = 0
    for model in models {
      let encoder = icbComputeFunction.makeArgumentEncoder(
                 bufferIndex: Int(BufferIndexModels.rawValue))
      let mBuffer = Renderer.device.makeBuffer(
               length: encoder.encodedLength, options: [])!
      encoder.setArgumentBuffer(mBuffer, offset: 0)
      encoder.setBuffer(model.vertexBuffer, offset: 0, index: 0)
      encoder.setBuffer(model.submesh.indexBuffer.buffer,
                        offset: 0, index: 1)
      encoder.setBuffer(model.texturesBuffer!, offset: 0, index: 2)
      encoder.setRenderPipelineState(model.pipelineState, index: 3)
      mBuffers.append(mBuffer)
      mBuffersLength += mBuffer.length
    }
    
    modelsBuffer = Renderer.device.makeBuffer(length: mBuffersLength,
                                              options: [])
    modelsBuffer.label = "Models Array Buffer"
    var offset = 0
    for mBuffer in mBuffers {
      var pointer = modelsBuffer.contents()
      pointer = pointer.advanced(by: offset)
      pointer.copyMemory(from: mBuffer.contents(), byteCount: mBuffer.length)
      offset += mBuffer.length
    }
    
    let drawLength = models.count *
        MemoryLayout<MTLDrawIndexedPrimitivesIndirectArguments>.stride
    drawArgumentsBuffer = Renderer.device.makeBuffer(length: drawLength,
                                                     options: [])!
    drawArgumentsBuffer.label = "Draw Arguments"
    
    var drawPointer =
       drawArgumentsBuffer.contents().bindMemory(
               to: MTLDrawIndexedPrimitivesIndirectArguments.self,
               capacity: models.count)
    for (modelIndex, model) in models.enumerated() {
      var drawArgument = MTLDrawIndexedPrimitivesIndirectArguments()
      drawArgument.indexCount = UInt32(model.submesh.indexCount)
      drawArgument.instanceCount = 1
      drawArgument.indexStart = UInt32(model.submesh.indexBuffer.offset)
      drawArgument.baseVertex = 0
      drawArgument.baseInstance = UInt32(modelIndex)
      drawPointer.pointee = drawArgument
      drawPointer = drawPointer.advanced(by: 1)
    }
   }
  
  static func buildDepthStencilState() -> MTLDepthStencilState? {
    let descriptor = MTLDepthStencilDescriptor()
    descriptor.depthCompareFunction = .less
    descriptor.isDepthWriteEnabled = true
    return
      Renderer.device.makeDepthStencilState(descriptor: descriptor)
  }
}

extension Renderer: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    camera.aspect = Float(view.bounds.width)/Float(view.bounds.height)
  }
  
  func updateUniforms() {
    // set the uniforms for the frame
    uniforms.projectionMatrix = camera.projectionMatrix
    uniforms.viewMatrix = camera.viewMatrix
    fragmentUniforms.cameraPosition = camera.position
    
    var bufferLength = MemoryLayout<Uniforms>.stride
    uniformsBuffer.contents().copyMemory(from: &uniforms,
                                         byteCount: bufferLength)
    bufferLength = MemoryLayout<FragmentUniforms>.stride
    fragmentUniformsBuffer.contents().copyMemory(from: &fragmentUniforms,
                                                 byteCount: bufferLength)

     var pointer = modelParamsBuffer.contents().bindMemory(to: ModelParams.self,
                                                           capacity: models.count)
     for model in models {
       pointer.pointee.modelMatrix = model.modelMatrix
       pointer.pointee.tiling = model.tiling
       pointer = pointer.advanced(by: 1)
     }
  }
  
  func draw(in view: MTKView) {
    guard
      let descriptor = view.currentRenderPassDescriptor,
      let commandBuffer = Renderer.commandQueue.makeCommandBuffer() else {
        return
    }

    updateUniforms()
    
    guard
       let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
         return
     }
     computeEncoder.setComputePipelineState(icbPipelineState)
     computeEncoder.setBuffer(uniformsBuffer, offset: 0,
                index: Int(BufferIndexUniforms.rawValue))
     computeEncoder.setBuffer(fragmentUniformsBuffer, offset: 0,
                index: Int(BufferIndexFragmentUniforms.rawValue))
     computeEncoder.setBuffer(drawArgumentsBuffer, offset: 0,
                index: Int(BufferIndexDrawArguments.rawValue))
     computeEncoder.setBuffer(modelParamsBuffer, offset: 0,
                index: Int(BufferIndexModelParams.rawValue))
     computeEncoder.setBuffer(modelsBuffer, offset: 0,
                index: Int(BufferIndexModels.rawValue))
     computeEncoder.setBuffer(icbBuffer, offset: 0,
                index: Int(BufferIndexICB.rawValue))
    
    computeEncoder.useResource(icb, usage: .write)
    computeEncoder.useResource(modelsBuffer, usage: .read)

    if let heap = TextureController.heap {
      computeEncoder.useHeap(heap)
    }

    for model in models {
      computeEncoder.useResource(model.vertexBuffer, usage: .read)
      computeEncoder.useResource(model.submesh.indexBuffer.buffer,
                                 usage: .read)
      computeEncoder.useResource(model.texturesBuffer!, usage: .read)
    }
    let threadExecutionWidth = icbPipelineState.threadExecutionWidth
    let threads = MTLSize(width: models.count, height: 1, depth: 1)
    let threadsPerThreadgroup = MTLSize(width: threadExecutionWidth,
                                        height: 1, depth: 1)
    computeEncoder.dispatchThreads(threads,
           threadsPerThreadgroup: threadsPerThreadgroup)
    computeEncoder.endEncoding()

    let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
    blitEncoder.optimizeIndirectCommandBuffer(icb, range: 0..<models.count)
    blitEncoder.endEncoding()
    
    guard let renderEncoder =
      commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
        return
    }
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.executeCommandsInBuffer(icb, range: 0..<models.count)
    renderEncoder.endEncoding()
    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
