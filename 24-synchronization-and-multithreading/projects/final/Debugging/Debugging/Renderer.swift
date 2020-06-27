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
  static var fps: Int!
  
  var semaphore: DispatchSemaphore
  let dispatchQueue = DispatchQueue(label: "Queue",
                                    attributes: .concurrent)
  
  var fragmentUniforms = FragmentUniforms()
  let depthStencilState: MTLDepthStencilState
  let lighting = Lighting()
  var scene: Scene?
  var computePipelineState: MTLComputePipelineState?
  
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
    Renderer.fps = metalView.preferredFramesPerSecond
    
    metalView.device = device
    metalView.depthStencilPixelFormat = .depth32Float
    
    depthStencilState = Renderer.buildDepthStencilState()!
    computePipelineState = Renderer.buildComputePipelineState()
    
    semaphore = DispatchSemaphore(value: Scene.buffersInFlight)
    
    super.init()
    metalView.clearColor = MTLClearColor(red: 0.7, green: 0.9,
                                         blue: 1, alpha: 1)

    metalView.delegate = self
    mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)

    fragmentUniforms.lightCount = lighting.count
    
    #if os(OSX)
    let devices = MTLCopyAllDevices()
    for device in devices {
      if #available(macOS 10.15, *) {
        if device.supportsFamily(.mac2) {
          print("\(device.name) is a Mac 2 family gpu running on macOS Catalina.")
        }
        else {
          print("\(device.name) is a Mac 1 family gpu running on macOS Catalina.")
        }
      }
      else {
        if device.supportsFeatureSet(.macOS_GPUFamily2_v1) {
          print("You are using a recent GPU with an older version of macOS.")
        }
        else {
          print("You are using an older GPU with an older version of macOS.")
        }
      }
    }
    #endif
  }
  

  static func buildDepthStencilState() -> MTLDepthStencilState? {
    let descriptor = MTLDepthStencilDescriptor()
    descriptor.depthCompareFunction = .less
    descriptor.isDepthWriteEnabled = true
    return
      Renderer.device.makeDepthStencilState(descriptor: descriptor)
  }
  
  static func buildComputePipelineState() -> MTLComputePipelineState {
    guard let kernelFunction =
      Renderer.library?.makeFunction(name: "compute") else {
        fatalError("Tessellation shader function not found")
    }
    return try!
      Renderer.device.makeComputePipelineState(function: kernelFunction)
  }
}

extension Renderer: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    scene?.sceneSizeWillChange(to: size)
  }
  
  func draw(in view: MTKView) {
    _ = semaphore.wait(timeout: .distantFuture)

    
    guard
      let scene = scene,
      let descriptor = view.currentRenderPassDescriptor,
      let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
      let renderEncoder =
      commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
        return
    }
    
    // update models
    let deltaTime = 1 / Float(Renderer.fps)
    scene.update(deltaTime: deltaTime)

    
    renderEncoder.setDepthStencilState(depthStencilState)

    var lights = lighting.lights
    renderEncoder.setFragmentBytes(&lights,
                                   length: MemoryLayout<Light>.stride * lights.count,
                                   index: Int(BufferIndexLights.rawValue))

    // render models
    scene.skybox?.update(renderEncoder: renderEncoder)
    let uniforms = scene.uniforms[scene.currentUniformIndex]
    for renderable in scene.renderables {
      renderEncoder.pushDebugGroup(renderable.name)
      renderable.render(renderEncoder: renderEncoder,
                        uniforms: uniforms,
                        fragmentUniforms: scene.fragmentUniforms)
      renderEncoder.popDebugGroup()
    }
    
    // render skybox
    scene.skybox?.render(renderEncoder: renderEncoder,
                         uniforms: uniforms)
    
    renderEncoder.endEncoding()
    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    
    // compute debugging
    guard let computeCommandBuffer =
              Renderer.commandQueue.makeCommandBuffer(),
    let computeEncoder =
                computeCommandBuffer.makeComputeCommandEncoder() else {
      fatalError()
    }
    computeEncoder.setComputePipelineState(computePipelineState!)
    let size = MTLSizeMake(4, 1, 1)
    computeEncoder.dispatchThreadgroups(size,
                                        threadsPerThreadgroup: size)
    computeEncoder.endEncoding()
    
    // 1
    commandBuffer.enqueue()
    computeCommandBuffer.enqueue()
    // 2
    dispatchQueue.async(execute: commandBuffer.commit)
    weak var sem = semaphore
    dispatchQueue.async {
      computeCommandBuffer.addCompletedHandler { _ in
        sem?.signal()
      }
      computeCommandBuffer.commit()
    }
    // 3
    __dispatch_barrier_sync(dispatchQueue) {}
    
  }
}
