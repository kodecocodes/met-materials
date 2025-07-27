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

struct VertexOut {
    float4 position [[position]];
    float3 direction;
};

vertex VertexOut vertex_main(
  uint vertexID [[vertex_id]],
  constant float4x4 &inverseViewProjection [[buffer(0)]])
{
  float3 cubeVertices[6] = {
    float3(-1, -1, 0),
    float3( 1, -1, 0),
    float3(-1,  1, 0),
    float3( 1, -1, 0),
    float3( 1,  1, 0),
    float3(-1,  1, 0)
  };
  float4 position = float4(cubeVertices[vertexID], 1);
  float4 worldDir = inverseViewProjection * position;

  VertexOut out;
  out.direction = normalize(worldDir.xyz);
  out.position = position;
  return out;
}

#define M_PI 3.14159265358979323846

fragment float4 fragment_main(
  VertexOut in [[stage_in]],
  texture2d<float> eqTexture [[texture(0)]])
{
  constexpr sampler s(
      filter::linear,
      address::clamp_to_edge
  );

  float3 dir = normalize(in.direction);

  float u = atan2(dir.z, dir.x) / (2.0 * M_PI) + 0.5;
  float v = asin(dir.y) / M_PI + 0.5;

  float3 color = eqTexture.sample(s, float2(1 - u, v)).rgb;

  // exposure 1.0 to 4.0
/*
  float exposure = 2.0;
  color = color * exposure;
*/

  // Simple tone mapping (Reinhard)
  //  color = color / (color + 1.0);

/*
  // Alternative: Unreal Engine filmic tone mapping approximation
  float A = 0.22;
  float B = 0.30;
  float C = 0.10;
  float D = 0.20;
  float E = 0.01;
  float F = 0.30;

  float3 x = max(float3(0.0), color);
  color = ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
*/

/*
  // Boost saturation
  float luminance = dot(color, float3(0.2126, 0.7152, 0.0722));
  color = mix(float3(luminance), color, 1.3); // 1.3 = 30% saturation boost
*/

  // Gamma correction
  color = pow(color, 1.0 / 2.2);

  return float4(color, 1.0);
}
