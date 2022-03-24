//: [Previous](@previous)
import MetalKit
import PlaygroundSupport

let size: CGFloat = 400
let renderer = Renderer(size: size)
let frame = CGRect(x: 0, y: 0, width: size, height: size)
let view = MTKView(frame: frame, device: renderer.device)
view.delegate = renderer
PlaygroundPage.current.liveView = view
