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
  static var colorPixelFormat: MTLPixelFormat!

  var uniforms = Uniforms()
  var fragmentUniforms = FragmentUniforms()
  let depthStencilState: MTLDepthStencilState
  let lighting = Lighting()

  lazy var camera: Camera = {
    let camera = ArcballCamera()
    camera.distance = 6
    camera.target = [0, 2.2, 0]
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
    Renderer.colorPixelFormat = metalView.colorPixelFormat
    metalView.device = device
    metalView.depthStencilPixelFormat = .depth32Float
    
    depthStencilState = Renderer.buildDepthStencilState()!
    super.init()
    metalView.clearColor = MTLClearColor(red: 0.93, green: 0.97,
                                         blue: 1.0, alpha: 1)
    metalView.delegate = self
    mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)

    // models
    let house = Model(name: "cottage1.obj")
    house.position = [0, 0, 0]
    house.rotation = [0, Float(50).degreesToRadians, 0]
    models.append(house)
    
    fragmentUniforms.lightCount = lighting.count
  }
  

  static func buildDepthStencilState() -> MTLDepthStencilState? {
    // 1
    let descriptor = MTLDepthStencilDescriptor()
    // 2
    descriptor.depthCompareFunction = .less
    // 3
    descriptor.isDepthWriteEnabled = true
    return
      Renderer.device.makeDepthStencilState(descriptor: descriptor)
  }
}

extension Renderer: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    camera.aspect = Float(view.bounds.width)/Float(view.bounds.height)
  }
  
  func draw(in view: MTKView) {
    guard
      let descriptor = view.currentRenderPassDescriptor,
      let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
      let renderEncoder =
      commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
        return
    }
    
    renderEncoder.setDepthStencilState(depthStencilState)

    uniforms.projectionMatrix = camera.projectionMatrix
    uniforms.viewMatrix = camera.viewMatrix
    fragmentUniforms.cameraPosition = camera.position
    
    var lights = lighting.lights
    renderEncoder.setFragmentBytes(&lights,
                                   length: MemoryLayout<Light>.stride * lights.count,
                                   index: Int(BufferIndexLights.rawValue))

    
    // render all the models in the array
    for model in models {
      
      // add tiling here
      fragmentUniforms.tiling = model.tiling
      renderEncoder.setFragmentBytes(&fragmentUniforms,
                                     length: MemoryLayout<FragmentUniforms>.stride,
                                     index: Int(BufferIndexFragmentUniforms.rawValue))
      
      renderEncoder.setFragmentSamplerState(model.samplerState, index: 0)
      
      uniforms.modelMatrix = model.modelMatrix
      uniforms.normalMatrix = uniforms.modelMatrix.upperLeft
      
      renderEncoder.setVertexBytes(&uniforms,
                                   length: MemoryLayout<Uniforms>.stride,
                                   index: Int(BufferIndexUniforms.rawValue))
      
      for mesh in model.meshes {

        // render multiple buffers
        // replace the following two lines
        // this only sends the MTLBuffer containing position, normal and UV
        let vertexBuffer = mesh.mtkMesh.vertexBuffers[0].buffer
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0,
                                      index: Int(BufferIndexVertices.rawValue))

        for submesh in mesh.submeshes {
          renderEncoder.setRenderPipelineState(submesh.pipelineState)
          // textures
          renderEncoder.setFragmentTexture(submesh.textures.baseColor,
                                           index: Int(BaseColorTexture.rawValue))
          renderEncoder.setFragmentTexture(submesh.textures.normal,
                                           index: Int(NormalTexture.rawValue))
          
          // set the materials here

          let mtkSubmesh = submesh.mtkSubmesh
          renderEncoder.drawIndexedPrimitives(type: .triangle,
                                              indexCount: mtkSubmesh.indexCount,
                                              indexType: mtkSubmesh.indexType,
                                              indexBuffer: mtkSubmesh.indexBuffer.buffer,
                                              indexBufferOffset: mtkSubmesh.indexBuffer.offset)
        }
      }
    }

    renderEncoder.endEncoding()
    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
