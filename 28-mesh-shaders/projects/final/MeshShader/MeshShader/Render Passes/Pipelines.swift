///// Copyright (c) 2025 Kodeco Inc.
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

enum PipelineStates {
  static func createPSO(descriptor: MTLRenderPipelineDescriptor)
  -> MTLRenderPipelineState {
    let pipelineState: MTLRenderPipelineState
    do {
      pipelineState =
      try Renderer.device.makeRenderPipelineState(
        descriptor: descriptor)
    } catch {
      fatalError(error.localizedDescription)
    }
    return pipelineState
  }

  static func createVertexPSO()
  -> MTLRenderPipelineState {
    let vertexFunction = Renderer.library.makeFunction(name: "vertex_main")
    let fragmentFunction = Renderer.library.makeFunction(name: "fragment_main")
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat
      = Renderer.viewColorPixelFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    return createPSO(descriptor: pipelineDescriptor)
  }

  static func createMeshPSO()
    -> MTLRenderPipelineState {
    let objectFunction: MTLFunction? = nil
    let meshFunction = Renderer.library.makeFunction(name: "mesh_main")
    let fragmentFunction =
      Renderer.library.makeFunction(name: "fragment_main")
    let pipelineDescriptor = MTLMeshRenderPipelineDescriptor()
    pipelineDescriptor.objectFunction = objectFunction
    pipelineDescriptor.meshFunction = meshFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat
      = Renderer.viewColorPixelFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    let meshPSO: MTLRenderPipelineState
    do {
      (meshPSO, _) = try Renderer.device.makeRenderPipelineState(
      descriptor: pipelineDescriptor, options: [])
    } catch {
      fatalError("Mesh PSO not created \(error.localizedDescription)")
    }
    return meshPSO
  }

  static func createGrassPSO()
    -> MTLRenderPipelineState {
    let objectFunction =
      Renderer.library.makeFunction(name: "object_grass")
    let meshFunction = Renderer.library.makeFunction(name: "mesh_grass")
    let fragmentFunction =
      Renderer.library.makeFunction(name: "fragment_main")
    let pipelineDescriptor = MTLMeshRenderPipelineDescriptor()
    pipelineDescriptor.objectFunction = objectFunction
    pipelineDescriptor.meshFunction = meshFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat
      = Renderer.viewColorPixelFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.payloadMemoryLength =
      MemoryLayout<GrassPayload>.stride
    let meshPSO: MTLRenderPipelineState
    do {
      (meshPSO, _) = try Renderer.device.makeRenderPipelineState(
      descriptor: pipelineDescriptor, options: [])
    } catch {
      fatalError("Mesh PSO not created \(error.localizedDescription)")
    }
    return meshPSO
  }
}
