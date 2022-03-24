
import MetalKit

public class Renderer: NSObject, MTKViewDelegate {
  
  public var device: MTLDevice!
  var queue: MTLCommandQueue!
  var pipelineState: MTLComputePipelineState!
  var time: Float = 0
  public let size: Int
  
  public init(size: CGFloat) {
    self.size = Int(size * 2)
    super.init()
    initializeMetal()
  }

  func initializeMetal() {
    device = MTLCreateSystemDefaultDevice()
    queue = device!.makeCommandQueue()
    do {
      let library = device.makeDefaultLibrary()
      guard let kernel = library?.makeFunction(name: "compute") else { fatalError() }
      pipelineState = try device.makeComputePipelineState(function: kernel)
    } catch let e {
      print(e)
    }
  }
  
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
  
  public func draw(in view: MTKView) {
    time += 0.01
    guard let commandBuffer = queue.makeCommandBuffer(),
          let commandEncoder = commandBuffer.makeComputeCommandEncoder(),
          let drawable = view.currentDrawable else { fatalError() }
    commandEncoder.setComputePipelineState(pipelineState)
    commandEncoder.setTexture(drawable.texture, index: 0)
    commandEncoder.setBytes(&time, length: MemoryLayout<Float>.size, index: 0)
    let w = pipelineState.threadExecutionWidth
    let h = pipelineState.maxTotalThreadsPerThreadgroup / w
    let threadsPerGroup = MTLSize(width: w, height: h, depth: 1)
    let threadsPerGrid = MTLSize(width: size, height: size, depth: 1)
    commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
    commandEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
