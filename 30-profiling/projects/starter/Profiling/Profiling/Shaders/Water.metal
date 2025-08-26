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

#include "Common.h"

struct VertexIn {
  float4 position [[attribute(Position)]];
  float2 uv [[attribute(UV)]];
};

struct VertexOut {
  float4 position [[position]];
  float4 worldPosition;
  float2 uv;
};

vertex VertexOut vertex_water(
  const VertexIn in [[stage_in]],
  constant Uniforms *uniforms [[buffer(UniformsBuffer)]],
  constant ModelTransform *model [[buffer(ModelTransformBuffer)]])
{
  float4x4 mvp = uniforms->projectionMatrix * uniforms->viewMatrix
  * model->modelMatrix;
  VertexOut out {
    .position = mvp * in.position,
    .uv = in.uv,
    .worldPosition = model->modelMatrix * in.position
  };
  return out;
}

fragment float4 fragment_water(
  VertexOut in [[stage_in]],
  constant Params &params [[buffer(ParamsBuffer)]],
  texture2d<float> reflectionTexture [[texture(0)]],
  texture2d<float> refractionTexture [[texture(1)]],
  texture2d<float> normalTexture [[texture(2)]],
  depth2d<float> depthMap [[texture(3)]],
  constant float& timer [[buffer(3)]],
  texturecube<float> skyboxTexture [[texture(SkyboxTexture)]])
{
  constexpr sampler s(filter::linear, address:: repeat);
  float3 viewDirection = normalize(in.worldPosition.xyz - params.cameraPosition);
  
  float foam = 0;
  float3 surfaceNormal = normalize(float3(0, 1, 0));
  if (is_null_texture(normalTexture) == false) {
    float2 waveUV1 = in.uv * 4.0 + float2(timer * 0.7, timer * 0.5);
    float2 waveUV2 = in.uv * 5.0 * 1.0 + float2(-timer * 0.9, timer * 0.3);
    float3 normal1 = normalTexture.sample(s, waveUV1).xyz * 2.0 - 1.0;
    float3 normal2 = normalTexture.sample(s, waveUV2).xyz * 2.0 - 1.0;
    float3 waveNormal = normalize(normal1 + normal2);
    float waveStrength = 0.2;
    surfaceNormal = normalize(mix(surfaceNormal, waveNormal, waveStrength));
    
    float waveHeight = (normal1.y + normal2.y) * 0.5;
    foam = smoothstep(0.4, 1.0, waveHeight);
  }
  
  float3 reflectionDirection = reflect(viewDirection, surfaceNormal);
  reflectionDirection.y = -abs(reflectionDirection.y);
  float3 reflectionColor = skyboxTexture.sample(s, reflectionDirection).rgb;

  float3 shallowColor = float3(0.5, 0.55, 0.7);
  float3 deepColor = float3(0.15, 0.2, 0.25);
  float depth = length(in.worldPosition.xyz - params.cameraPosition) / 1000.0;
  depth = saturate(depth);
  float3 oceanColor = mix(shallowColor, deepColor, 1 - depth);

  float fresnel = dot(-viewDirection, surfaceNormal);
  float3 color = mix(oceanColor, reflectionColor, fresnel);
  color = mix(color, float3(0.9), foam * 2);
  
  // Fade alpha based on distance
  float distance = length(in.worldPosition.xz);
  float maxDistance = 180.0;
  float alpha = smoothstep(0.0, maxDistance, distance);
  alpha = mix(0.5, 1.0, alpha);

  return float4(color, alpha);
}
