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

  let depthStencilState: MTLDepthStencilState

  // Lights
  lazy var sunlight: Light = {
    var light = buildDefaultLight()
    light.position = [1, 2, -2]
    return light
  }()
  lazy var ambientLight: Light = {
    var light = buildDefaultLight()
    light.color = [0.5, 1, 0]
    light.intensity = 0.1
    light.type = Ambientlight
    return light
  }()
  lazy var redLight: Light = {
    var light = buildDefaultLight()
    light.position = [-0, 0.5, -0.5]
    light.color = [1, 0, 0]
    light.attenuation = float3(1, 3, 4)
    light.type = Pointlight
    return light
  }()
  lazy var spotlight: Light = {
    var light = buildDefaultLight()
    light.position = [0.4, 0.8, 1]
    light.color = [1, 0, 1]
    light.attenuation = float3(1, 0.5, 0)
    light.type = Spotlight
    light.coneAngle = Float(40).degreesToRadians
    light.coneDirection = [-2, 0, -1.5]
    light.coneAttenuation = 12
    return light
  }()
  var lights: [Light] = []

  // Camera holds view and projection matrices
  lazy var camera: Camera = {
    let camera = ArcballCamera()
    camera.distance = 2.5
    camera.target = [0.5, 0.5, 0]
    camera.rotation.x = Float(-10).degreesToRadians
    return camera
  }()

  // Array of Models allows for rendering multiple models
  var models: [Model] = []
  
  // Debug drawing of lights
  lazy var lightPipelineState: MTLRenderPipelineState = {
    return buildLightPipelineState()
  }()

  
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
    metalView.clearColor = MTLClearColor(red: 1.0, green: 1.0,
                                         blue: 0.8, alpha: 1.0)
    metalView.delegate = self
    
    // add the model to the scene
    let train = Model(name: "train.obj")
    train.position = [0, 0, 0]
    train.rotation = [0, Float(45).degreesToRadians, 0]
    models.append(train)
    let fir = Model(name: "treefir.obj")
    fir.position = [1.4, 0, 0]
    models.append(fir)

    mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
    lights.append(sunlight)
    lights.append(ambientLight)
    lights.append(redLight)
    lights.append(spotlight)
    fragmentUniforms.lightCount = UInt32(lights.count)
  }
  
  func buildDefaultLight() -> Light {
    var light = Light()
    light.position = [0, 0, 0]
    light.color = [1, 1, 1]
    light.specularColor = [0.6, 0.6, 0.6]
    light.intensity = 1
    light.attenuation = float3(1, 0, 0)
    light.type = Sunlight
    return light
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
    
    renderEncoder.setFragmentBytes(&lights,
                                   length: MemoryLayout<Light>.stride * lights.count,
                                   index: 2)
    renderEncoder.setFragmentBytes(&fragmentUniforms,
                                   length: MemoryLayout<FragmentUniforms>.stride,
                                   index: 3)
    
    // render all the models in the array
    for model in models {
      // model matrix now comes from the Model's superclass: Node
      uniforms.modelMatrix = model.modelMatrix
      uniforms.normalMatrix = uniforms.modelMatrix.upperLeft

      renderEncoder.setVertexBytes(&uniforms,
                                   length: MemoryLayout<Uniforms>.stride, index: 1)
      
      renderEncoder.setRenderPipelineState(model.pipelineState)

      for mesh in model.meshes {
        let vertexBuffer = mesh.mtkMesh.vertexBuffers[0].buffer
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0,
                                      index: 0)
        
        for submesh in mesh.submeshes {
          let mtkSubmesh = submesh.mtkSubmesh
          renderEncoder.drawIndexedPrimitives(type: .triangle,
                                              indexCount: mtkSubmesh.indexCount,
                                              indexType: mtkSubmesh.indexType,
                                              indexBuffer: mtkSubmesh.indexBuffer.buffer,
                                              indexBufferOffset: mtkSubmesh.indexBuffer.offset)
        }
      }
    }

    debugLights(renderEncoder: renderEncoder, lightType: Spotlight)
    
    renderEncoder.endEncoding()
    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
