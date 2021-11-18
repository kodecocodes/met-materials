//: [Previous](@previous)
import MetalKit
import PlaygroundSupport

let renderer = Renderer()
let side = renderer.side / 2
let frame = CGRect(x: 0, y: 0, width: side, height: side)
let view = MTKView(frame: frame, device: renderer.device)
view.delegate = renderer
PlaygroundPage.current.liveView = view

//: [Next](@next)
