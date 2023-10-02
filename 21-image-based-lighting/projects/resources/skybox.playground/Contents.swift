import SwiftUI
import PlaygroundSupport

struct ContentView: View {
  @State var options = Options()

  var body: some View {
    VStack {
      MetalView(options: options)
        .border(Color.black, width: 2)
        .frame(width: 500, height: 500)
      SlidersView(options: options)
    }
  }
}

let view = ContentView()
let hostingVC = UIHostingController(rootView: view)
PlaygroundPage.current.liveView = hostingVC

