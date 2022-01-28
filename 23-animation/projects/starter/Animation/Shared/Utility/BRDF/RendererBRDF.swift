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
import Metal

extension Renderer {
  static func buildBRDF() -> MTLTexture? {
    let size = 256
    let brdfPipelineState =
      PipelineStates.createComputePSO(function: "integrateBRDF")
    guard let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
      let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        else { return nil }
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .rg16Float,
      width: size,
      height: size,
      mipmapped: false)
    descriptor.usage = [.shaderRead, .shaderWrite]
    let lut = Renderer.device.makeTexture(descriptor: descriptor)
    computeEncoder.setComputePipelineState(brdfPipelineState)
    computeEncoder.setTexture(lut, index: 0)
    let threadsPerThreadgroup = MTLSizeMake(16, 16, 1)
    let threadgroups = MTLSize(
      width: size / threadsPerThreadgroup.width,
      height: size / threadsPerThreadgroup.height,
      depth: 1)
    computeEncoder.dispatchThreadgroups(
      threadgroups,
      threadsPerThreadgroup: threadsPerThreadgroup)
    computeEncoder.endEncoding()
    commandBuffer.commit()
    return lut
  }
}
