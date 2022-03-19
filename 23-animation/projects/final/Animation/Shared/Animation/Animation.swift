/// Copyright (c) 2022 Razeware LLC
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

struct Keyframe<Value> {
  var time: Float = 0
  var value: Value
}

struct Animation {
  var translations: [Keyframe<float3>] = []
  var rotations: [Keyframe<simd_quatf>] = []
  var repeatAnimation = true

  func getTranslation(at time: Float) -> float3? {
    // 1
    guard let lastKeyframe = translations.last else {
      return nil
    }
    // 2
    var currentTime = time
    if let first = translations.first,
      first.time >= currentTime {
      return first.value
    }
    // 3
    if currentTime >= lastKeyframe.time,
      !repeatAnimation {
      return lastKeyframe.value
    }
    // 1
    currentTime = fmod(currentTime, lastKeyframe.time)
    // 2
    let keyFramePairs = translations.indices.dropFirst().map {
      (previous: translations[$0 - 1], next: translations[$0])
    }
    // 3
    guard let (previousKey, nextKey) = (keyFramePairs.first {
      currentTime < $0.next.time
    })
    else { return nil }
    // 4
    let interpolant =
      (currentTime - previousKey.time) /
      (nextKey.time - previousKey.time)
    // 5
    return simd_mix(
      previousKey.value,
      nextKey.value,
      float3(repeating: interpolant))
  }

  func getRotation(at time: Float) -> simd_quatf? {
    guard let lastKeyframe = rotations.last else {
      return nil
    }
    var currentTime = time
    if let first = rotations.first,
      first.time >= currentTime {
      return first.value
    }
    if currentTime >= lastKeyframe.time,
      !repeatAnimation {
      return lastKeyframe.value
    }
    currentTime = fmod(currentTime, lastKeyframe.time)
    let keyFramePairs = rotations.indices.dropFirst().map {
      (previous: rotations[$0 - 1], next: rotations[$0])
    }
    guard let (previousKey, nextKey) = (keyFramePairs.first {
      currentTime < $0.next.time
    })
    else { return nil }
    let interpolant =
      (currentTime - previousKey.time) /
      (nextKey.time - previousKey.time)
    return simd_slerp(
      previousKey.value,
      nextKey.value,
      interpolant)
  }
}
