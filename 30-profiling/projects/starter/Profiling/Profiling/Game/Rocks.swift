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

import Foundation

enum Rocks {
  static let modelNames = [
    "rock1.obj",
    "rock2.obj",
    "rock3.obj"
  ]
  static let textureNames = [
    "rock1", "rock2", "rock3"
  ]
  static let positions: [float3] = [
    [4.23, 2.30, 1.14],
    [4.85, 2.43, 2.31],
    [3.5, 2.1, 2.32],
    [4.39, 2.14, 3.67],
    [4.44, 2.05, 5.13],
    [5.22, 2.32, 6.55],
    [5.4, 2.27, 7.84],
    [5.01, 2.11, 9.38],
    [2.62, 1.65, 3.35],
    [2.64, 1.57, 4.5],
    [3.1, 1.77, 5.6],
    [3.46, 1.88, 6.85],
    [3.92, 1.93, 8.2],
    [1.65, 1.47, 6.33],
    [2.55, 1.6, 7.9],
    [3.28, 1.79, 9.39],
    [1.7, 1.46, 8.94],
    [2.3, 1.54, 10.28]
  ]

  static func instanceRocks() -> Nature {
    let rocks = Nature(
      name: "Rocks",
      instanceCount: positions.count,
      textureNames: textureNames,
      morphTargetNames: modelNames)
    for index in 0..<positions.count {
      var transform = Transform()
      transform.position = positions[index]
      transform.rotation.x = .random(in: 0...Float.pi)
      transform.rotation.z = .random(in: 0...Float.pi)
      transform.scale = .random(in: 1...1.5)
      let textureID = Int.random(in: 0..<textureNames.count)
      let morphID = Int.random(in: 0..<modelNames.count)
      rocks.updateBuffer(
        instance: index,
        transform: transform,
        textureID: textureID,
        morphTargetID: morphID)
    }
    return rocks
  }

  static func setupRocks() -> [Model] {
    let rocks = positions.map { position in
      var rock = Model(name: modelNames[Int.random(in: 0..<modelNames.count)])
      rock.position = position
      rock.rotation.x = .random(in: 0...Float.pi)
      rock.rotation.z = .random(in: 0...Float.pi)
      rock.scale = .random(in: 1...1.5)
      rock.setTexture(name: textureNames[Int.random(in: 0..<textureNames.count)], type: BaseColor)
      return rock
    }
    return rocks
  }
}
