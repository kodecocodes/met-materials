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

#import "Common.h"

kernel void clearScreen(
  texture2d<half, access::write> output [[texture(0)]],
  uint2 id [[thread_position_in_grid]])
{
  output.write(half4(0.0, 0.0, 0.0, 1.0), id);
}

kernel void fireworks(
  texture2d<half, access::write> output [[texture(0)]],
  device Particle *particles [[buffer(0)]],
  uint id [[thread_position_in_grid]]) {
  float xVelocity = particles[id].speed
    * cos(particles[id].direction);
  float yVelocity = particles[id].speed
    * sin(particles[id].direction) + 3.0;
  particles[id].position.x += xVelocity;
  particles[id].position.y += yVelocity;
  particles[id].life -= 1.0;
  half4 color;
  color = half4(particles[id].color) * particles[id].life / 255.0;
  color.a = 1.0;
  uint2 position = uint2(particles[id].position);
  output.write(color, position);
  output.write(color, position + uint2(0, 1));
  output.write(color, position - uint2(0, 1));
  output.write(color, position + uint2(1, 0));
  output.write(color, position - uint2(1, 0));
}
