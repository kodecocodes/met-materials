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

float G1V(float nDotV, float k)
{
  return 1.0f / (nDotV * (1.0f - k) + k);
}

float3 calculateSpecular(
  Light light,
  Material material,
  float3 viewDirection,
  float3 normal)
{
  float3 lightDirection = normalize(light.position);
  float3 F0 = mix(0.04, material.baseColor, material.metallic);
  // add a small amount of bias so that you can
  // see the shininess when roughness is zero
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

  float3 specular = nDotL * D * F * vis;
  return specular;
}

// specular optimized-ggx
// AUTHOR John Hable. Released into the public domain
float3 computeSpecular(
  constant Light *lights,
  constant Params &params,
  Material material,
  float3 normal)
{
  float3 viewDirection = normalize(params.cameraPosition);
  float3 specularTotal = 0;
  for (uint i = 0; i < params.lightCount; i++) {
    Light light = lights[i];
    if (light.type != Sun) { continue; }
    float3 specular = calculateSpecular(light, material, viewDirection, normal);
    specularTotal += specular;
  }
  return specularTotal;
}
