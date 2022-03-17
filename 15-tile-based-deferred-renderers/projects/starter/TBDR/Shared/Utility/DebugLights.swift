/// Copyright (c) 2022 Razeware LLC
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

enum DebugLights {
  static let linePipelineState: MTLRenderPipelineState = {
    let library = Renderer.library
    let vertexFunction = library?.makeFunction(name: "vertex_debug")
    let fragmentFunction = library?.makeFunction(name: "fragment_debug_line")
    let psoDescriptor = MTLRenderPipelineDescriptor()
    psoDescriptor.vertexFunction = vertexFunction
    psoDescriptor.fragmentFunction = fragmentFunction
    psoDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    psoDescriptor.depthAttachmentPixelFormat = .depth32Float
    let pipelineState: MTLRenderPipelineState
    do {
      pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: psoDescriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
    return pipelineState
  }()

  static let pointPipelineState: MTLRenderPipelineState = {
    let library = Renderer.library
    let vertexFunction = library?.makeFunction(name: "vertex_debug")
    let fragmentFunction = library?.makeFunction(name: "fragment_debug_point")
    let psoDescriptor = MTLRenderPipelineDescriptor()
    psoDescriptor.vertexFunction = vertexFunction
    psoDescriptor.fragmentFunction = fragmentFunction
    psoDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    psoDescriptor.depthAttachmentPixelFormat = .depth32Float
    let pipelineState: MTLRenderPipelineState
    do {
      pipelineState = try Renderer.device.makeRenderPipelineState(
        descriptor: psoDescriptor
      )
    } catch let error {
      fatalError(error.localizedDescription)
    }
    return pipelineState
  }()

  static func draw(lights: [Light], encoder: MTLRenderCommandEncoder, uniforms: Uniforms) {
    encoder.label = "Debug lights"
    for light in lights {
      switch light.type {
      case Point:
        debugDrawPoint(
          encoder: encoder,
          uniforms: uniforms,
          position: light.position,
          color: light.color)
      case Spot:
        debugDrawPoint(
          encoder: encoder,
          uniforms: uniforms,
          position: light.position,
          color: light.color)
        debugDrawLine(
          renderEncoder: encoder,
          uniforms: uniforms,
          position: light.position,
          direction: light.coneDirection,
          color: light.color)
      case Sun:
        debugDrawDirection(
          renderEncoder: encoder,
          uniforms: uniforms,
          direction: light.position,
          color: [1, 0, 0],
          count: 5)
      default:
        break
      }
    }
  }

  static func debugDrawPoint(
    encoder: MTLRenderCommandEncoder,
    uniforms: Uniforms,
    position: float3,
    color: float3
  ) {
    var vertices = [position]
    encoder.setVertexBytes(&vertices, length: MemoryLayout<float3>.stride, index: 0)
    var uniforms = uniforms
    uniforms.modelMatrix = .identity
    encoder.setVertexBytes(
      &uniforms,
      length: MemoryLayout<Uniforms>.stride,
      index: UniformsBuffer.index)
    var lightColor = color
    encoder.setFragmentBytes(
      &lightColor,
      length: MemoryLayout<float3>.stride,
      index: 1)
    encoder.setRenderPipelineState(pointPipelineState)
    encoder.drawPrimitives(
      type: .point,
      vertexStart: 0,
      vertexCount: vertices.count)
  }

  static func debugDrawDirection(
    renderEncoder: MTLRenderCommandEncoder,
    uniforms: Uniforms,
    direction: float3,
    color: float3,
    count: Int
  ) {
    var vertices: [float3] = []
    for i in -count..<count {
      let value = Float(i) * 0.4
      vertices.append(float3(value, 0, value))
      vertices.append(
        float3(
          direction.x + value,
          direction.y,
          direction.z + value))
    }
    let buffer = Renderer.device.makeBuffer(
      bytes: &vertices,
      length: MemoryLayout<float3>.stride * vertices.count,
      options: [])
    var uniforms = uniforms
    uniforms.modelMatrix = .identity
    renderEncoder.setVertexBytes(
      &uniforms,
      length: MemoryLayout<Uniforms>.stride,
      index: UniformsBuffer.index)
    var lightColor = color
    renderEncoder.setFragmentBytes(&lightColor, length: MemoryLayout<float3>.stride, index: 1)
    renderEncoder.setVertexBuffer(buffer, offset: 0, index: 0)
    renderEncoder.setRenderPipelineState(linePipelineState)
    renderEncoder.drawPrimitives(
      type: .line,
      vertexStart: 0,
      vertexCount: vertices.count)
  }

  static func debugDrawLine(
    renderEncoder: MTLRenderCommandEncoder,
    uniforms: Uniforms,
    position: float3,
    direction: float3,
    color: float3
  ) {
    var vertices: [float3] = []
    vertices.append(position)
    vertices.append(float3(
      position.x + direction.x,
      position.y + direction.y,
      position.z + direction.z))
    let buffer = Renderer.device.makeBuffer(
      bytes: &vertices,
      length: MemoryLayout<float3>.stride * vertices.count,
      options: [])
    var uniforms = uniforms
    uniforms.modelMatrix = .identity
    renderEncoder.setVertexBytes(
      &uniforms,
      length: MemoryLayout<Uniforms>.stride,
      index: UniformsBuffer.index)
    var lightColor = color
    renderEncoder.setFragmentBytes(&lightColor, length: MemoryLayout<float3>.stride, index: 1)
    renderEncoder.setVertexBuffer(buffer, offset: 0, index: 0)
    // render line
    renderEncoder.setRenderPipelineState(linePipelineState)
    renderEncoder.drawPrimitives(
      type: .line,
      vertexStart: 0,
      vertexCount: vertices.count)
    // render starting point
    renderEncoder.setRenderPipelineState(pointPipelineState)
    renderEncoder.drawPrimitives(
      type: .point,
      vertexStart: 0,
      vertexCount: 1)
  }
}
