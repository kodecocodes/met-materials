
import MetalKit
import PlaygroundSupport

let frame = CGRect(x: 0, y: 0, width: 800, height: 500)
let delegate = Renderer()
let view = MTKView(frame: frame, device: delegate.device)
view.delegate = delegate
PlaygroundPage.current.liveView = view


import MetalKit
import MetalPerformanceShaders

public class Renderer: NSObject, MTKViewDelegate {
  
  public var device: MTLDevice!
  var queue: MTLCommandQueue!
  var texIn: MTLTexture!
  
  public override init() {
    device = MTLCreateSystemDefaultDevice()!
    queue = device.makeCommandQueue()
    let textureLoader = MTKTextureLoader(device: device)
    let url = Bundle.main.url(
      forResource: "fruit.jpg", withExtension: "")!
    do {
      texIn = try textureLoader.newTexture(
        URL: url, options: [:])
    }
    catch {
      fatalError(error.localizedDescription)
    }
  }
  
  public func draw(in view: MTKView) {
    guard let commandBuffer = queue.makeCommandBuffer(),
          let drawable = view.currentDrawable else { return }
    let shader = MPSImageSobel(device: device)
    shader.encode(
      commandBuffer: commandBuffer,
      sourceTexture: texIn,
      destinationTexture: drawable.texture)
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
  
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
}
