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
  }
  
  func draw(in view: MTKView) {
    guard
      let descriptor = view.currentRenderPassDescriptor,
      let commandBuffer = Renderer.commandQueue.makeCommandBuffer() else {
        return
    }

    updateUniforms()
    
    guard let renderEncoder =
      commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
        return
    }
    renderEncoder.setDepthStencilState(depthStencilState)

    renderEncoder.setVertexBytes(&uniforms,
                                 length: MemoryLayout<Uniforms>.stride,
                                 index: Int(BufferIndexUniforms.rawValue))
    renderEncoder.setFragmentBytes(&fragmentUniforms,
                                   length: MemoryLayout<FragmentUniforms>.stride,
                                   index: Int(BufferIndexFragmentUniforms.rawValue))

    // render all the models in the array
    for model in models {
      renderEncoder.pushDebugGroup(model.name)
      // set the constants for each model
      modelParams.modelMatrix = model.modelMatrix
      renderEncoder.setVertexBytes(&modelParams,
                                   length: MemoryLayout<ModelParams>.stride,
                                   index: Int(BufferIndexModelParams.rawValue))

      modelParams.tiling = model.tiling
      renderEncoder.setFragmentBytes(&modelParams,
                                     length: MemoryLayout<ModelParams>.stride,
                                     index: Int(BufferIndexModelParams.rawValue))
      
      
      renderEncoder.setRenderPipelineState(model.pipelineState)
      renderEncoder.setVertexBuffer(model.vertexBuffer, offset: 0,
                                    index: 0)
      
      renderEncoder.setFragmentTexture(model.colorTexture,
                                       index: Int(BaseColorTexture.rawValue))
      renderEncoder.setFragmentTexture(model.normalTexture,
                                       index: Int(NormalTexture.rawValue))
      
      let mtkSubmesh = model.submesh
      renderEncoder.drawIndexedPrimitives(type: .triangle,
                                          indexCount: mtkSubmesh.indexCount,
                                          indexType: mtkSubmesh.indexType,
                                          indexBuffer: mtkSubmesh.indexBuffer.buffer,
                                          indexBufferOffset: mtkSubmesh.indexBuffer.offset)
      renderEncoder.popDebugGroup()
    }
    renderEncoder.endEncoding()
    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
