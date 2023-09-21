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

import Foundation
import MetalKit

// swiftlint:disable function_body_length

enum DebugCameraFrustum {
  static var forwardVectorBuffer: MTLBuffer?
  static var frustumMesh: [float3] = []
  static var frustumVertexBuffer: MTLBuffer?

  static var nearPoints = FrustumPoints()
  static var farPoints = FrustumPoints()
  static var sphereMesh: MTLBuffer?
  static var sphereSubmesh: MTKSubmesh?
  static var sphereVertexDescriptor: MTLVertexDescriptor?
  static var sphereCenter: float3 = .zero
  static var sphereRadius: Float = 0

  static func createSphereMesh(camera: Camera) {
    guard let camera = camera as? ArcballCamera else { return }
    nearPoints = ArcballCamera.calculatePlane(camera: camera, distance: camera.near)
    farPoints = ArcballCamera.calculatePlane(camera: camera, distance: camera.far)
    let radius1 = distance(nearPoints.lowerLeft, farPoints.upperRight) * 0.5
    let radius2 = distance(farPoints.lowerLeft, farPoints.upperRight) * 0.5
    if radius1 > radius2 {
      sphereCenter = simd_mix(nearPoints.lowerLeft, farPoints.upperRight, [0.5, 0.5, 0.5])
    } else {
      sphereCenter = simd_mix(farPoints.lowerLeft, farPoints.upperRight, [0.5, 0.5, 0.5])
    }
    sphereRadius = max(radius1, radius2)
    let allocator = MTKMeshBufferAllocator(device: Renderer.device)
    let mdlMesh = MDLMesh(
      sphereWithExtent: [sphereRadius, sphereRadius, sphereRadius],
      segments: [10, 10],
      inwardNormals: false,
      geometryType: .triangles,
      allocator: allocator)
    let mesh: MTKMesh
    do {
      mesh = try MTKMesh(mesh: mdlMesh, device: Renderer.device)
    } catch {
      fatalError("Failed to create mesh")
    }
    sphereMesh = mesh.vertexBuffers[0].buffer
    sphereSubmesh = mesh.submeshes.first
    sphereVertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
  }

  static func createMesh(from camera: Camera) {
    if let camera = camera as? ArcballCamera {
      nearPoints = ArcballCamera.calculatePlane(camera: camera, distance: camera.near)
      farPoints = ArcballCamera.calculatePlane(camera: camera, distance: camera.far)
    } else if let camera = camera as? OrthographicCamera {
      nearPoints = OrthographicCamera.calculatePlane(camera: camera, distance: camera.near)
      farPoints = OrthographicCamera.calculatePlane(camera: camera, distance: camera.far)
    }
    frustumMesh = [
      nearPoints.upperLeft, nearPoints.upperRight, nearPoints.upperRight, nearPoints.lowerRight,
      nearPoints.lowerRight, nearPoints.lowerLeft, nearPoints.lowerLeft, nearPoints.upperLeft,
      nearPoints.upperLeft, farPoints.upperLeft, farPoints.upperLeft, farPoints.lowerLeft,
      farPoints.lowerLeft, nearPoints.lowerLeft,
      nearPoints.upperRight, farPoints.upperRight, farPoints.upperRight, farPoints.lowerRight,
      farPoints.lowerRight, nearPoints.lowerRight,
      farPoints.upperLeft, farPoints.upperRight,
      farPoints.lowerLeft, farPoints.lowerRight
    ]
    frustumVertexBuffer = Renderer.device.makeBuffer(
      bytes: frustumMesh,
      length: MemoryLayout<float3>.stride * frustumMesh.count,
      options: [])

    // camera axes mesh
    let matrix = farPoints.viewMatrix
    let forwardVector: float3 = [matrix.columns.0.z, matrix.columns.1.z, matrix.columns.2.z]
    let rightVector: float3 = [matrix.columns.0.x, matrix.columns.1.x, matrix.columns.2.x]
    let upVector = cross(forwardVector, rightVector)
    let forwardVectorMesh = [
      camera.position, camera.position + forwardVector,
      camera.position, camera.position + rightVector,
      camera.position, camera.position + upVector
    ]
    forwardVectorBuffer = Renderer.device.makeBuffer(
      bytes: forwardVectorMesh,
      length: MemoryLayout<float3>.stride * forwardVectorMesh.count,
      options: [])
  }

  static func draw(encoder: MTLRenderCommandEncoder, scene: GameScene, uniforms: Uniforms) {
    if scene.shouldDrawMainCamera {
      if let mainCamera = scene.debugMainCamera {
        Self.render(encoder: encoder, camera: mainCamera, uniforms: uniforms)
      }
    }
    if scene.shouldDrawLightCamera {
      if let shadowCamera = scene.debugShadowCamera {
        Self.render(encoder: encoder, camera: shadowCamera, uniforms: uniforms)
      }
    }
    if scene.shouldDrawBoundingSphere {
      if let camera = scene.debugMainCamera {
        Self.renderSphere(camera: camera, encoder: encoder, uniforms: uniforms)
      }
    }
  }

  static func render(encoder: MTLRenderCommandEncoder, camera: Camera, uniforms: Uniforms) {
    var color: float3
    var camera = camera
    var debugString: String
    if camera is ArcballCamera {
      color = float3(0, 1, 1)
      debugString = "Camera"
    } else {
      color = float3(1, 1, 0)
      debugString = "Light Camera"
    }
    createMesh(from: camera)
    encoder.setVertexBuffer(
      frustumVertexBuffer,
      offset: 0,
      index: 0)

    // create the pipeline state
    let vertexFunction = Renderer.library?.makeFunction(name: "vertex_frustum")
    let fragmentFunction = Renderer.library?.makeFunction(name: "fragment_frustum")
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    var pipelineState: MTLRenderPipelineState
    do {
      pipelineState =
        try Renderer.device.makeRenderPipelineState(
          descriptor: pipelineDescriptor)
    } catch {
      fatalError("Failed to create debug pipeline state \(error.localizedDescription)")
    }
    encoder.setRenderPipelineState(pipelineState)
    encoder.pushDebugGroup("\(debugString) Point")
    var uniforms = uniforms
    encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: UniformsBuffer.index)
    encoder.setVertexBytes(&camera.position, length: MemoryLayout<float3>.stride, index: 0)
    encoder.setFragmentBytes(&color, length: MemoryLayout<float3>.stride, index: ColorBuffer.index)
    encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: 1)
    encoder.popDebugGroup()

    encoder.pushDebugGroup("\(debugString) Frustum")
    encoder.setTriangleFillMode(.lines)
    encoder.setVertexBuffer(frustumVertexBuffer, offset: 0, index: 0)
    encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: frustumMesh.count)
    encoder.popDebugGroup()

    // render axes
    // forward
    encoder.pushDebugGroup("\(debugString) Axes")
    color = [0, 0, 1]
    encoder.setFragmentBytes(&color, length: MemoryLayout<float3>.stride, index: ColorBuffer.index)
    encoder.setVertexBuffer(forwardVectorBuffer, offset: 0, index: 0)
    encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: 2)
    // right
    color = [1, 0, 0]
    encoder.setFragmentBytes(&color, length: MemoryLayout<float3>.stride, index: ColorBuffer.index)
    encoder.drawPrimitives(type: .line, vertexStart: 2, vertexCount: 2)
    // up
    color = [0, 1, 0]
    encoder.setFragmentBytes(&color, length: MemoryLayout<float3>.stride, index: ColorBuffer.index)
    encoder.drawPrimitives(type: .line, vertexStart: 4, vertexCount: 2)
    encoder.popDebugGroup()
  }

  static func renderSphere(camera: Camera, encoder: MTLRenderCommandEncoder, uniforms: Uniforms) {
    // render sphere
    if !(camera is ArcballCamera) { return }
    createSphereMesh(camera: camera)
    encoder.pushDebugGroup("Bounding Sphere")
    // create the pipeline state
    let vertexFunction = Renderer.library?.makeFunction(name: "vertex_debug_cameraSphere")
    let fragmentFunction = Renderer.library?.makeFunction(name: "fragment_frustum")
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.vertexDescriptor = sphereVertexDescriptor
    var pipelineState: MTLRenderPipelineState
    do {
      pipelineState =
        try Renderer.device.makeRenderPipelineState(
          descriptor: pipelineDescriptor)
    } catch {
      fatalError("Failed to create debug pipeline state \(error.localizedDescription)")
    }
    encoder.setRenderPipelineState(pipelineState)
    encoder.setTriangleFillMode(.lines)
    var color = float3(1, 1, 1)
    encoder.setFragmentBytes(&color, length: MemoryLayout<float3>.stride, index: ColorBuffer.index)
    let sphereTransform = Transform(position: sphereCenter)
    var uniforms = uniforms
    uniforms.modelMatrix = sphereTransform.modelMatrix
    encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: UniformsBuffer.index)
    encoder.setVertexBuffer(
      sphereMesh,
      offset: 0,
      index: 0)
    if let submesh = sphereSubmesh {
      encoder.drawIndexedPrimitives(
        type: .triangle,
        indexCount: submesh.indexCount,
        indexType: submesh.indexType,
        indexBuffer: submesh.indexBuffer.buffer,
        indexBufferOffset: 0)
    }
    encoder.popDebugGroup()
  }
}

private extension MTLVertexDescriptor {
  static var positionLayout: MTLVertexDescriptor? {
    MTKMetalVertexDescriptorFromModelIO(.defaultLayout)
  }
}

private extension MDLVertexDescriptor {
  static var positionLayout: MDLVertexDescriptor = {
    let vertexDescriptor = MDLVertexDescriptor()

    // Position
    vertexDescriptor.attributes[Position.index]
      = MDLVertexAttribute(
        name: MDLVertexAttributePosition,
        format: .float3,
        offset: 0,
        bufferIndex: VertexBuffer.index)
    vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<float3>.stride)
    return vertexDescriptor
  }()
}
// swiftlint:enable function_body_length
