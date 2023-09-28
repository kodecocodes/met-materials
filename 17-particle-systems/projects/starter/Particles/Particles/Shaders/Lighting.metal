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
#import "Lighting.h"

float3 calculateSun(
  Light light,
  float3 normal,
  Params params,
  Material material)
{
  float3 lightDirection = normalize(light.position);
  float nDotL = saturate(dot(normal, lightDirection));
  float3 diffuse = float3(material.baseColor) * (1.0 - material.metallic);
  return diffuse * nDotL * material.ambientOcclusion * light.color;
}

float3 calculatePoint(
  Light light,
  float3 fragmentWorldPosition,
  float3 normal,
  Material material)
{
  float d = distance(light.position, fragmentWorldPosition);
  float3 lightDirection = normalize(light.position - fragmentWorldPosition);

  float attenuation = 1.0 / (light.attenuation.x +
      light.attenuation.y * d + light.attenuation.z * d * d);
  //attenuation = 1.0 / (light.attenuation.x + light.attenuation.y * d);
  float diffuseIntensity =
      saturate(dot(normal, lightDirection));
  float3 color = light.color * material.baseColor * diffuseIntensity;
  color *= attenuation;
  if (color.r + color.g + color.b < 0.01) {
    color = 0;
  }
  return color;
}

float calculateShadow(
  float4 shadowPosition,
  depth2d<float> shadowTexture)
{
  // shadow calculation
  float3 position
    = shadowPosition.xyz / shadowPosition.w;
  float2 xy = position.xy;
  xy = xy * 0.5 + 0.5;
  xy.y = 1 - xy.y;
  constexpr sampler s(
    coord::normalized, filter::nearest,
    address::clamp_to_edge,
    compare_func:: less);
  float shadow_sample = shadowTexture.sample(s, xy);
  return (position.z > shadow_sample + 0.001) ? 0.5 : 1;
}

