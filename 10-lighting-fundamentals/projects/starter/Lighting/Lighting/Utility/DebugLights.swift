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

// debug drawing
extension Renderer {
  
  func buildLightPipelineState() -> MTLRenderPipelineState {
    let library = Renderer.device.makeDefaultLibrary()
    let vertexFunction = library?.makeFunction(name: "vertex_light")
    let fragmentFunction = library?.makeFunction(name: "fragment_light")
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    let lightPipelineState: MTLRenderPipelineState
    do {
      lightPipelineState = try Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
    return lightPipelineState
  }
  
   // uncomment when you have defined `lights`
  /*
  func debugLights(renderEncoder: MTLRenderCommandEncoder, lightType: LightType) {
    for light in lights where light.type == lightType {
      switch light.type {
      case Pointlight:
        drawPointLight(renderEncoder: renderEncoder, position: light.position,
                       color: light.color)
      case Spotlight:
        drawPointLight(renderEncoder: renderEncoder, position: light.position,
                       color: light.color)
   
//        leave this commented until you define spotlights
//        drawSpotLight(renderEncoder: renderEncoder, position: light.position,
//                      direction: light.coneDirection, color: light.color)
      case Sunlight:
        drawDirectionalLight(renderEncoder: renderEncoder, direction: light.position,
                             color: [1, 0, 0], count: 5)
      default:
        break
      }
    }
  }
 */
  
  func drawPointLight(renderEncoder: MTLRenderCommandEncoder, position: float3, color: float3) {
    var vertices = [position]
    let buffer = Renderer.device.makeBuffer(bytes: &vertices,
                                            length: MemoryLayout<float3>.stride * vertices.count,
                                            options: [])
    uniforms.modelMatrix = float4x4.identity()
    renderEncoder.setVertexBytes(&uniforms,
                                 length: MemoryLayout<Uniforms>.stride, index: 1)
    var lightColor = color
    renderEncoder.setFragmentBytes(&lightColor, length: MemoryLayout<float3>.stride, index: 1)
    renderEncoder.setVertexBuffer(buffer, offset: 0, index: 0)
    renderEncoder.setRenderPipelineState(lightPipelineState)
    renderEncoder.drawPrimitives(type: .point, vertexStart: 0,
                                 vertexCount: vertices.count)
    
  }
  
  func drawDirectionalLight (renderEncoder: MTLRenderCommandEncoder,
                             direction: float3,
                             color: float3, count: Int) {
    var vertices: [float3] = []
    for i in -count..<count {
      let value = Float(i) * 0.4
      vertices.append(float3(value, 0, value))
      vertices.append(float3(direction.x+value, direction.y, direction.z+value))
    }

    let buffer = Renderer.device.makeBuffer(bytes: &vertices,
                                            length: MemoryLayout<float3>.stride * vertices.count,
                                            options: [])
    uniforms.modelMatrix = float4x4.identity()
    renderEncoder.setVertexBytes(&uniforms,
                                 length: MemoryLayout<Uniforms>.stride, index: 1)
    var lightColor = color
    renderEncoder.setFragmentBytes(&lightColor, length: MemoryLayout<float3>.stride, index: 1)
    renderEncoder.setVertexBuffer(buffer, offset: 0, index: 0)
    renderEncoder.setRenderPipelineState(lightPipelineState)
    renderEncoder.drawPrimitives(type: .line, vertexStart: 0,
                                 vertexCount: vertices.count)
    
  }
  
  func drawSpotLight(renderEncoder: MTLRenderCommandEncoder, position: float3, direction: float3, color: float3) {
    var vertices: [float3] = []
    vertices.append(position)
    vertices.append(float3(position.x + direction.x, position.y + direction.y, position.z + direction.z))
    let buffer = Renderer.device.makeBuffer(bytes: &vertices,
                                            length: MemoryLayout<float3>.stride * vertices.count,
                                            options: [])
    uniforms.modelMatrix = float4x4.identity()
    renderEncoder.setVertexBytes(&uniforms,
                                 length: MemoryLayout<Uniforms>.stride, index: 1)
    var lightColor = color
    renderEncoder.setFragmentBytes(&lightColor, length: MemoryLayout<float3>.stride, index: 1)
    renderEncoder.setVertexBuffer(buffer, offset: 0, index: 0)
    renderEncoder.setRenderPipelineState(lightPipelineState)
    renderEncoder.drawPrimitives(type: .line, vertexStart: 0,
                                 vertexCount: vertices.count)
  }
  
  
}

