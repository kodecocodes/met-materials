
import MetalKit
import PlaygroundSupport

let frame = CGRect(x: 0, y: 0, width: 400, height: 400)
let mView = Renderer()
let view = MTKView(frame: frame, device: mView.device)
view.delegate = mView
PlaygroundPage.current.liveView = view

//: [Next](@next)
