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

#import "Lighting.h"

float3 calculateSunDiffuse(
  Light light,
  float3 normal,
  Params params,
  Material material)
{
  float3 lightDirection = normalize(light.position);
  float nDotL = saturate(dot(normal, lightDirection));
  float3 surfaceColor = material.baseColor * light.color * light.intensity;
  float3 diffuse = surfaceColor * (1.0 - material.metallic) * nDotL;
  return diffuse * material.ambientOcclusion;
}

float3 calculatePointDiffuse(
  Light light,
  float3 normal,
  Material material,
  float3 worldPosition)
{
  
  float d = distance(light.position, worldPosition);
  float3 lightDirection = normalize(light.position - worldPosition);
  float attenuation = 1.0 / (light.attenuation.x +
      light.attenuation.y * d + light.attenuation.z * d * d);

  float diffuseIntensity =
      saturate(dot(lightDirection, normal));
  float3 surfaceColor = material.baseColor * light.color * light.intensity;
  float3 color = surfaceColor * diffuseIntensity;
  color *= attenuation;
  if (color.r + color.g + color.b < 0.01) {
    color = 0;
  }
  return color;
}

float G1V(float nDotV, float k)
{
  return 1.0f / (nDotV * (1.0f - k) + k);
}

float3 calculateSunSpecular(
  Light light,
  Material material,
  float3 viewDirection,
  float3 normal)
{
  float3 lightDirection = normalize(light.position);
  float3 F0 = mix(0.04, material.baseColor, material.metallic);
  float bias = 0.01;
  float roughness = material.roughness + bias;
  float alpha = roughness * roughness;
  float3 halfVector = normalize(viewDirection + lightDirection);
  float nDotL = saturate(dot(normal, lightDirection));
  float nDotV = saturate(dot(normal, viewDirection));
  float nDotH = saturate(dot(normal, halfVector));
  float lDotH = saturate(dot(lightDirection, halfVector));

  float3 F;
  float D, vis;

  // Distribution
  float alphaSqr = alpha * alpha;
  float pi = 3.14159f;
  float denom = nDotH * nDotH * (alphaSqr - 1.0) + 1.0f;
  D = alphaSqr / (pi * denom * denom);

  // Fresnel
  float lDotH5 = pow(1.0 - lDotH, 5);
  F = F0 + (1.0 - F0) * lDotH5;

  // V
  float k = alpha / 2.0f;
  vis = G1V(nDotL, k) * G1V(nDotV, k);

  float3 specular = nDotL * D * F * vis * light.specularColor;
  return specular;
}

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

float3 enhanceColor(float3 color, float contrast, float saturation) {
    // Contrast
    color = (color - 0.5) * contrast + 0.5;
    
    // Saturation
    float luminance = dot(color, float3(0.299, 0.587, 0.114));
    color = mix(float3(luminance), color, saturation);
    return color;
}
