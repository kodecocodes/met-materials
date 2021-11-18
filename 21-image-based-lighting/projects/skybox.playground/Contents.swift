import Cocoa
import PlaygroundSupport

// Setup Metal
let device = MTLCreateSystemDefaultDevice()!
let frame = NSRect(x: 0, y: 0, width: 800, height: 800)
var metalViewFrame = frame
metalViewFrame.origin.y = 200
metalViewFrame.size.height = 600
let metalView = MetalView(frame: metalViewFrame, device: device)
let view = SlidersView(frame: frame, metalView: metalView)
view.addSubview(metalView)
PlaygroundPage.current.liveView = view
metalView.renderer = Renderer(metalView: metalView)
