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

public typealias float2 = SIMD2<Float>
public typealias float3 = SIMD3<Float>
public typealias float4 = SIMD4<Float>

public class Renderer: NSObject, MTKViewDelegate {
    
  public let device: MTLDevice!
  let commandQueue: MTLCommandQueue!
  
  let particleCount = 10000
  let maxEmitters = 8
  var emitters: [Emitter] = []
  let life: Float = 256
  var timer: Float = 0
  
  let pipelineState: MTLComputePipelineState!
  let particlePipelineState: MTLComputePipelineState!
  
  override public init() {
    let initialized = Renderer.initializeMetal()
    device = initialized?.device
    commandQueue = initialized?.commandQueue
    
    pipelineState = initialized?.pipelineState
    particlePipelineState = initialized?.particlePipelineState
    super.init()
  }
  
  private static func initializeMetal() -> (
    device: MTLDevice, commandQueue: MTLCommandQueue,
    pipelineState: MTLComputePipelineState,
    particlePipelineState: MTLComputePipelineState)?
  {
    guard let device = MTLCreateSystemDefaultDevice(),
      let commandQueue = device.makeCommandQueue(),
      let path = Bundle.main.path(forResource: "Shaders",
                                  ofType: "metal") else { return nil }
    
    let pipelineState: MTLComputePipelineState
    let particlePipelineState: MTLComputePipelineState
    
    do {
      let input = try String(contentsOfFile: path,
                             encoding: String.Encoding.utf8)
      let library = try device.makeLibrary(source: input, options: nil)
      guard let function = library.makeFunction(name: "compute"),
        let particleFunction = library.makeFunction(name: "particleKernel") else { return nil }
      pipelineState = try device.makeComputePipelineState(function: function)
      particlePipelineState = try
        device.makeComputePipelineState(function: particleFunction)
    }
    catch {
      print(error.localizedDescription)
      return nil
    }
    return (
      device, commandQueue,
      pipelineState: pipelineState, particlePipelineState: particlePipelineState)
  }
  
  func update(size: CGSize) {
    timer += 1
    if timer >= 50 {
      timer = 0
      if emitters.count > maxEmitters {
        emitters.removeFirst()
      }
      let emitter = Emitter(particleCount: particleCount,
                            size: size, life: life,
                            device: device)
      emitters.append(emitter)
    }
  }
  
  func makeRenderCommandEncoder(_ commandBuffer: MTLCommandBuffer, _ texture: MTLTexture) -> MTLRenderCommandEncoder {
    let descriptor = MTLRenderPassDescriptor()
    let color = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
    descriptor.colorAttachments[0].texture = texture
    descriptor.colorAttachments[0].clearColor = color
    descriptor.colorAttachments[0].loadAction = .clear
    guard let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
      fatalError("Cannot create a render command encoder.")
    }
    return renderCommandEncoder
  }
  
  public func draw(in view: MTKView) {
    guard let commandBuffer = commandQueue.makeCommandBuffer(),
          let drawable = view.currentDrawable else {
      return
    }
    update(size: view.drawableSize)
    
    // first command encoder
    guard let computeEncoder = commandBuffer.makeComputeCommandEncoder()
      else { return }
    computeEncoder.setComputePipelineState(pipelineState)
    computeEncoder.setTexture(drawable.texture, index: 0)

    var width = pipelineState.threadExecutionWidth
    var height = pipelineState.maxTotalThreadsPerThreadgroup / width
    let threadsPerThreadgroup = MTLSizeMake(width, height, 1)
    width = Int(view.drawableSize.width)
    height = Int(view.drawableSize.height)
    var threadsPerGrid = MTLSizeMake(width, height, 1)

    computeEncoder.dispatchThreads(threadsPerGrid,
                                   threadsPerThreadgroup: threadsPerThreadgroup)
    computeEncoder.endEncoding()
    
    // second command encoder
    guard let particleEncoder = commandBuffer.makeComputeCommandEncoder()
      else { return }
    particleEncoder.setComputePipelineState(particlePipelineState)
    particleEncoder.setTexture(drawable.texture, index: 0)
    threadsPerGrid = MTLSizeMake(particleCount, 1, 1)
    for emitter in emitters {
      let particleBuffer = emitter.particleBuffer
      particleEncoder.setBuffer(particleBuffer, offset: 0, index: 0)
      particleEncoder.dispatchThreads(threadsPerGrid,
                                      threadsPerThreadgroup: threadsPerThreadgroup)
    }
    particleEncoder.endEncoding()
    
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
  
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
