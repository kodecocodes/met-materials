
import MetalKit

public class Renderer: NSObject, MTKViewDelegate {
  
  public var device: MTLDevice!
  var queue: MTLCommandQueue!
  var pipelineState: MTLComputePipelineState!
  var time: Float = 0
  public let side = 1200
  
  override public init() {
    super.init()
    initializeMetal()
  }
  
  func initializeMetal() {
    device = MTLCreateSystemDefaultDevice()
    queue = device!.makeCommandQueue()
    do {
      guard let path = Bundle.main.path(forResource: "Shaders", ofType: "metal") else { fatalError() }
      let input = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
      let library = try device.makeLibrary(source: input, options: nil)
      guard let kernel = library.makeFunction(name: "compute") else { fatalError() }
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
    let threadsPerGroup = MTLSizeMake(w, h, 1)
    let threadsPerGrid = MTLSizeMake(side, side, 1)
    commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
    commandEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
