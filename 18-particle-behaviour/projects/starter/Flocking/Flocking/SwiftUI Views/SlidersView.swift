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

// swiftlint:disable unused_closure_parameter

struct SlidersView: View {
  @Bindable var options: Options

  init(options: Options) {
    self.options = options
  }

  var body: some View {
    VStack {
      HStack {
        VStack {
          HStack {
            Text("Cohesion Strength:")
            Slider(value: $options.cohesionStrength, in: 0...0.01) { editing in
            }
            Text("\(options.cohesionStrength, specifier: "%.3f")")
          }
          HStack {
            Text("Separation Strength:")
            Slider(value: $options.separationStrength, in: 0...0.1) { editing in
            }
            Text("\(options.separationStrength, specifier: "%.2f")")
          }
          HStack {
            Text("Alignment Strength:")
            Slider(value: $options.alignmentStrength, in: 0...0.1) { editing in
            }
            Text("\(options.alignmentStrength, specifier: "%.2f")")
          }
        }
        VStack {
          HStack {
            Text("ParticleCount:")
            Slider(value: $options.particles, in: 2...1000) { editing in}
            Text("\(options.particleCount)")
          }

          HStack {
            Text("Minimum Speed:")
            Slider(value: $options.minSpeed, in: 0.1...50) { editing in
              if options.maxSpeed < options.minSpeed {
                options.maxSpeed = options.minSpeed
              }
            }
            Text("\(options.minSpeed, specifier: "%.1f")")
            Spacer()
            Text("Maximum Speed:")
            Slider(value: $options.maxSpeed, in: 0.1...50) { editing in
              if options.minSpeed > options.maxSpeed {
                options.minSpeed = options.maxSpeed
              }
            }
            Text("\(options.maxSpeed, specifier: "%.1f")")
          }
          HStack {
            VStack {
              HStack {
                Text("Radius for neigbors:")
                Slider(value: $options.neighborRadius, in: 50...1000) { editing in
                }
                Text("\(options.neighborRadius, specifier: "%.0f")")
              }
            }
            HStack {
              Text("Separation radius:")
              Slider(value: $options.separationRadius, in: 0...100) { editing in
              }
              Text("\(options.separationRadius, specifier: "%.0f")")
            }
          }
        }
      }
      Divider()
      VStack(alignment: .leading) {
        Text("Predator")
          .font(.subheadline)
          .fontWeight(.bold)
        HStack {
          HStack {
            Text("Strength:")
            Slider(value: $options.predatorStrength, in: 0...0.1) { editing in
            }
            Text("\(options.predatorStrength, specifier: "%.2f")")
          }
          HStack {
            Text("Avoid Predator Radius:")
            Slider(value: $options.predatorRadius, in: 50...1000) { editing in
            }
            Text("\(options.predatorRadius, specifier: "%.0f")")
          }
          HStack {
            Text("Seek Distance:")
            Slider(value: $options.predatorSeek, in: 50...1000) { editing in
            }
            Text("\(options.predatorSeek, specifier: "%.0f")")
          }
          HStack {
            Text("Speed:")
            Slider(value: $options.predatorSpeed, in: 0.1...30) { editing in
            }
            Text("\(options.predatorSpeed, specifier: "%.0f")")
          }
        }
      }
      .padding()
    }
    .font(.caption)
    .padding()
  }
}
// swiftlint:enable unused_closure_parameter
