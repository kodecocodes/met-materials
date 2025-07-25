import SwiftUI
import MetalKit

public struct MetalView: View {
  let options: Options
  @State private var metalView = MTKView()
  @State private var previousTranslation = CGSize.zero
  @State private var previousScroll: CGFloat = 1
  @State private var renderer: Renderer?

  public init(options: Options) {
    self.options = options
  }

  public var body: some View {
    MetalViewRepresentable(
      metalView: $metalView)
    .onAppear {
      renderer = Renderer(
        metalView: metalView,
        options: options)
    }
    .gesture(DragGesture(minimumDistance: 0)
      .onChanged { value in
        InputController.shared.touchLocation = value.location
        InputController.shared.touchDelta = CGSize(
          width: value.translation.width - previousTranslation.width,
          height: value.translation.height - previousTranslation.height)
        previousTranslation = value.translation
        // if the user drags, cancel the tap touch
        if abs(value.translation.width) > 1 ||
            abs(value.translation.height) > 1 {
          InputController.shared.touchLocation = nil
        }
      }
      .onEnded {_ in
        previousTranslation = .zero
      })
    .gesture(MagnificationGesture()
      .onChanged { value in
        let scroll = value - previousScroll
        InputController.shared.mouseScroll.x = Float(scroll)
        * Settings.touchZoomSensitivity
        previousScroll = value
      }
      .onEnded {_ in
        previousScroll = 1
      })
  }
}
typealias ViewRepresentable = NSViewRepresentable

public struct MetalViewRepresentable: ViewRepresentable {
  @Binding var metalView: MTKView

  public func makeNSView(context: Context) -> MTKView {
    metalView
  }

  public func updateNSView(_ nsView: MTKView, context: Context) {
    updateMetalView()
  }

  func updateMetalView() {
  }
}

#Preview {
  VStack {
    MetalView(options: Options())
    Text("Metal View")
  }
}
