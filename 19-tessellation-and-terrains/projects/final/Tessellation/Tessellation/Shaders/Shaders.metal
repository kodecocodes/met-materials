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
#include "Common.h"

using namespace metal;

struct VertexOut {
  float4 position [[position]];
  float4 color;
  float height;
  float2 uv;
};

struct ControlPoint {
  float4 position [[attribute(0)]];
};

[[patch(quad, 4)]]
vertex VertexOut
  vertex_main(
    patch_control_point<ControlPoint> control_points [[stage_in]],
    constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
    float2 patch_coord [[position_in_patch]],
    texture2d<float> heightMap [[texture(0)]],
    constant Terrain &terrain [[buffer(6)]],
    uint patchID [[patch_id]])
{
  float u = patch_coord.x;
  float v = patch_coord.y;

  float2 top = mix(
    control_points[0].position.xz,
    control_points[1].position.xz,
    u);
  float2 bottom = mix(
    control_points[3].position.xz,
    control_points[2].position.xz,
    u);

  VertexOut out;
  float2 interpolated = mix(top, bottom, v);
  float4 position = float4(
    interpolated.x, 0.0,
    interpolated.y, 1.0);

  float2 xy = (position.xz + terrain.size / 2.0) / terrain.size;
  constexpr sampler sample;
  float4 color = heightMap.sample(sample, xy);
  out.color = float4(color.r);
  float height = (color.r * 2 - 1) * terrain.height;
  position.y = height;

  out.position = uniforms.mvp * position;
  out.uv = xy;
  out.height = height;

  return out;
}

fragment float4 fragment_main(
  VertexOut in [[stage_in]],
  texture2d<float> cliffTexture [[texture(1)]],
  texture2d<float> snowTexture  [[texture(2)]],
  texture2d<float> grassTexture [[texture(3)]])
{
  constexpr sampler sample(filter::linear, address::repeat);
  float tiling = 16.0;
  float4 color;
  if (in.height < -0.5) {
    color = grassTexture.sample(sample, in.uv * tiling);
  } else if (in.height < 0.3) {
    color = cliffTexture.sample(sample, in.uv * tiling);
  } else {
    color = snowTexture.sample(sample, in.uv * tiling);
  }
  return color;
}

