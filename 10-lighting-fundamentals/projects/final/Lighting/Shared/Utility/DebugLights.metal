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

#include <metal_stdlib>
using namespace metal;

#import "../Shaders/Common.h"

struct VertexOut {
  float4 position [[position]];
  float point_size [[point_size]];
};

vertex VertexOut vertex_debug(
  constant float3 *vertices [[buffer(0)]],
  constant Uniforms &uniforms [[buffer(UniformsBuffer)]],
  uint id [[vertex_id]])
{
  matrix_float4x4 mvp = uniforms.projectionMatrix
    * uniforms.viewMatrix * uniforms.modelMatrix;
  VertexOut out {
    .position = mvp * float4(vertices[id], 1),
    .point_size = 25.0
  };
  return out;
}

fragment float4 fragment_debug_point(
  float2 point [[point_coord]],
  constant float3 &color [[buffer(1)]])
{
  float d = distance(point, float2(0.5, 0.5));
  if (d > 0.5) {
    discard_fragment();
  }
  return float4(color, 1);
}

fragment float4 fragment_debug_line(
  constant float3 &color [[buffer(1)]])
{
  return float4(color ,1);
}

