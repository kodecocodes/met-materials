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

#include <metal_stdlib>
using namespace metal;
#include "Helper.h"

float2 wrapPosition(float2 position, float2 size) {
  float width = size.x;
  float height = size.y;
  float2 newPosition = position;
  if (position.x < 0) {
    newPosition.x = width;
  } else if (position.x > width) {
    newPosition.x = 0;
  }
  if (position.y < 0) {
    newPosition.y = height;
  } else if (position.y > height) {
    newPosition.y = 0;
  }
  return newPosition;
}

Boid bounceBoid(float2 position, float2 velocity, float2 size) {
  float2 newPosition = position;
  float2 newVelocity = velocity;
  float width = size.x;
  float height = size.y;
  if (position.x < 0 || position.x > width) {
    newVelocity.x *= -1;
    if (position.x < 0) {
      newPosition.x = 25;
    } else if (position.x > width) {
      newPosition.x = width - 25;
    }
  }
  if (position.y < 0 || position.y > height) {
    newVelocity.y *= -1;
    if (position.y < 0) {
      newPosition.y = 25;
    } else if (position.y > height) {
      newPosition.y = height - 25;
    }
  }
  return Boid { newPosition, newVelocity };
}

