///// Copyright (c) 2025 Kodeco Inc.
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

public struct SlidersView: View {
  @Bindable public var options: Options

  public init(options: Options) {
    self.options = options
  }

  public var body: some View {
      VStack {
        Text("Texture is regenerated after each slider is moved")
          .font(.caption2)
          .fontWeight(.bold)
        HStack {
          Text("Turbidity:")
          Slider(value: $options.turbidity) { editing in
            if !editing {
              options.shouldGenerateSkybox = true
            }
          }
          Text("\(options.turbidity, specifier: "%.2f")")
        }
        HStack {
          Text("Sun Elevation:")
          Slider(value: $options.sunElevation) { editing in
            if !editing {
              options.shouldGenerateSkybox = true
            }
          }
          Text("\(options.sunElevation, specifier: "%.2f")")
        }
        HStack {
          Text("Upper Atmosphere:")
          Slider(value: $options.upperAtmosphereScattering) { editing in
            if !editing {
              options.shouldGenerateSkybox = true
            }
          }
          Text("\(options.upperAtmosphereScattering, specifier: "%.2f")")
        }
        HStack {
          Text("Ground Albedo (0 to 10):")
          Slider(value: $options.groundAlbedo, in: 0...10) { editing in
            if !editing {
              options.shouldGenerateSkybox = true
            }
          }
          Text("\(options.groundAlbedo, specifier: "%.2f")")
        }
      }
      .font(.caption)
      .padding()
  }
}

