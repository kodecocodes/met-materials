///// Copyright (c) 2023 Kodeco Inc.
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SwiftUI

let originalColor = Color(red: 0.8, green: 0.8, blue: 0.8)
let size: CGFloat = 400

struct ContentView: View {
  @State private var showGrid = true

  var body: some View {
    VStack(alignment: .leading) {
      ZStack {
        MetalView()
          .border(Color.black, width: 2)
        if showGrid {
          Grid()
        }
      }
      .frame(width: size, height: size)
      ZStack(alignment: .top) {
        Key()
        Toggle("Show Grid", isOn: $showGrid)
          .padding(.leading, 250)
      }
    }
    .padding()
  }
}

struct Key: View {
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Rectangle()
          .foregroundColor(originalColor)
          .frame(width: 20, height: 20)
        Text("Original triangle")
      }
      HStack {
        Rectangle()
          .foregroundColor(.red)
          .frame(width: 20, height: 20)
        Text("Transformed triangle")
      }
    }
    .padding(0)
  }
}

struct Grid: View {
  var cellSize: CGFloat = size / 20
  var body: some View {
    ZStack {
      HStack {
        ForEach(0..<Int(cellSize), id: \.self) { _ in
          Spacer()
          Divider()
        }
      }
      VStack {
        ForEach(0..<Int(cellSize), id: \.self) { _ in
          Spacer()
          Divider()
        }
      }
      Rectangle()
        .frame(height: 1)
        .frame(maxWidth: .infinity)
      Rectangle()
        .frame(width: 1)
        .frame(maxHeight: .infinity)
    }
  }
}

#Preview {
  ContentView()
}
