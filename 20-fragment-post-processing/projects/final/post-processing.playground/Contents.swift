
import MetalKit
import PlaygroundSupport

let device = MTLCreateSystemDefaultDevice()!
let frame = NSRect(x: 0, y: 0, width: 800, height: 800)
let view = MetalView(frame: frame, device: device)
view.renderer = Renderer(metalView: view)
PlaygroundPage.current.liveView = view
