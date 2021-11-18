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

typealias float2 = SIMD2<Float>

class Renderer: NSObject {
  
  var device: MTLDevice!
  var queue: MTLCommandQueue!
  var firstState: MTLComputePipelineState!
  var secondState: MTLComputePipelineState!
  var emitter: Emitter!
  var particleCount = 100
  
  init(metalView: MTKView) {
    super.init()
    initializeMetal(metalView: metalView)
    emitter = Emitter(particleCount: particleCount, size: metalView.drawableSize, device: device)
  }
  
  func initializeMetal(metalView: MTKView) {
    metalView.framebufferOnly = false
    device = metalView.device
    queue = device.makeCommandQueue()
    let library = device.makeDefaultLibrary()
    do {
      guard let firstPass = library?.makeFunction(name: "firstPass") else { return }
      firstState = try device.makeComputePipelineState(function: firstPass)
      guard let secondPass = library?.makeFunction(name: "secondPass") else { return }
      secondState = try device.makeComputePipelineState(function: secondPass)
    } catch let error {
      print(error)
    }
  }
}

extension Renderer: MTKViewDelegate {
  func draw(in view: MTKView) {
    guard let commandBuffer = queue.makeCommandBuffer(),
      let commandEncoder = commandBuffer.makeComputeCommandEncoder(),
      let drawable = view.currentDrawable else {
        return
    }
    // first pass
    commandEncoder.setComputePipelineState(firstState)
    commandEncoder.setTexture(drawable.texture, index: 0)
    let width = firstState.threadExecutionWidth
    let height = firstState.maxTotalThreadsPerThreadgroup / width
    var threadsPerGroup = MTLSizeMake(width, height, 1)
    var threadsPerGrid = MTLSizeMake(Int(view.drawableSize.width),
                                     Int(view.drawableSize.height),
                                     1)
    #if os(iOS)
    if device.supportsFeatureSet(.iOS_GPUFamily4_v1) {
      commandEncoder.dispatchThreads(threadsPerGrid,
                                     threadsPerThreadgroup: threadsPerGroup)
    } else {
      let width = (view.drawableSize.width / CGFloat(width)).rounded(.up)
      let height = (view.drawableSize.height / CGFloat(height)).rounded(.up)
      let groupsPerGrid = MTLSize(width: Int(width),
                                  height: Int(height),
                                  depth: 1)
      commandEncoder.dispatchThreadgroups(groupsPerGrid,
                                          threadsPerThreadgroup: threadsPerGroup)
    }
    #elseif os(macOS)
    commandEncoder.dispatchThreads(threadsPerGrid,
                                   threadsPerThreadgroup: threadsPerGroup)
    #endif
    
    // second pass
    commandEncoder.setComputePipelineState(secondState)
    commandEncoder.setTexture(drawable.texture,
                              index: 0)
    threadsPerGroup = MTLSizeMake(1, 1, 1)
    threadsPerGrid = MTLSizeMake(particleCount, 1, 1)
    commandEncoder.setBuffer(emitter.particleBuffer,
                             offset: 0,
                             index: 0)
    commandEncoder.setBytes(&particleCount,
                            length: MemoryLayout<Int>.stride,
                            index: 1)
    #if os(iOS)
    if device.supportsFeatureSet(.iOS_GPUFamily4_v1) {
      commandEncoder.dispatchThreads(threadsPerGrid,
                                     threadsPerThreadgroup: threadsPerGroup)
    } else {
      let threads = min(firstState.threadExecutionWidth,
                        particleCount)
      let threadsPerThreadgroup = MTLSize(width: threads,
                                          height: 1,
                                          depth: 1)
      let groups = particleCount / threads + 1
      let groupsPerGrid = MTLSize(width: groups,
                                  height: 1,
                                  depth: 1)
      commandEncoder.dispatchThreadgroups(groupsPerGrid,
                                          threadsPerThreadgroup: threadsPerThreadgroup)
    }
    #elseif os(macOS)
    commandEncoder.dispatchThreads(threadsPerGrid,
                                   threadsPerThreadgroup: threadsPerGroup)
    #endif
    commandEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
  
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
