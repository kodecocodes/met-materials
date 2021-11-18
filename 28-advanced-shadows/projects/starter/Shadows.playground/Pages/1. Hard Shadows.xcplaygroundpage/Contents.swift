import MetalKit
import PlaygroundSupport

let renderer = Renderer()
let frame = NSRect(x: 0, y: 0, width: 600, height: 600)
let view = MTKView(frame: frame, device: renderer.device)
view.delegate = renderer
PlaygroundPage.current.liveView = view
//: [Next](@next)
