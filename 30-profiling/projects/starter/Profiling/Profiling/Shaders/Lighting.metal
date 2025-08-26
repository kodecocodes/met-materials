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

#include <metal_stdlib>
using namespace metal;

#include "Lighting.h"

float calculateSoftShadow(float4 shadowPosition, depth2d<float> shadowTexture) {
  float3 position = shadowPosition.xyz / shadowPosition.w;
  float2 xy = position.xy;
  xy = xy * 0.5 + 0.5;
  xy.y = 1 - xy.y;
  
  // no shadow outside shadow map
  if (xy.x < 0.0 || xy.x > 1.0 || xy.y < 0.0 || xy.y > 1.0) {
    return 1.0;
  }
  
  constexpr sampler s(
    coord::normalized, filter::linear,
    address::clamp_to_edge);
  
  float shadow = 0.0;
  float2 dimensions = float2(shadowTexture.get_width(), shadowTexture.get_height());
  float2 texelSize = 1.0 / dimensions;
  
  // 3x3 PCF
  for(int x = -1; x <= 1; ++x) {
    for(int y = -1; y <= 1; ++y) {
      float2 offset = float2(x, y) * texelSize;
      float shadowMapDepth = shadowTexture.sample(s, xy + offset);
      if (shadowMapDepth >= 0.999) { // nothing on shadow map
        shadow += 1.0;
      } else {
        shadow += (position.z > shadowMapDepth + 0.002) ? 0.0 : 1.0;
      }
    }
  }
  shadow /= 9.0;
  return mix(0.5, 1.0, shadow);
}
