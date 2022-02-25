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

#import "Vertex.h"
#import "Lighting.h"
#import "Material.h"

constant float pi = 3.1415926535897932384626433832795;

// functions
float3 computeSpecular(
  float3 normal,
  float3 viewDirection,
  float3 lightDirection,
  float roughness,
  float3 F0);

float3 computeDiffuse(
  Material material,
  float3 normal,
  float3 lightDirection);

fragment float4 fragment_PBR(
  FragmentIn in [[stage_in]],
  constant Params &params [[buffer(ParamsBuffer)]],
  constant Light *lights [[buffer(LightBuffer)]],
  constant ShaderMaterial &shaderMaterial [[buffer(MaterialBuffer)]],
  depth2d<float> shadowTexture [[texture(ShadowTexture)]])
{
  constexpr sampler textureSampler(
    filter::linear,
    address::repeat,
    mip_filter::linear);
  
  Material material = shaderMaterial.material;
  texture2d<float> baseColorTexture = shaderMaterial.baseColorTexture;
  texture2d<float> normalTexture = shaderMaterial.normalTexture;
  texture2d<float> metallicTexture = shaderMaterial.metallicTexture;
  texture2d<float> roughnessTexture = shaderMaterial.roughnessTexture;
  texture2d<float> aoTexture = shaderMaterial.aoTexture;
  texture2d<float> opacityTexture = shaderMaterial.opacityTexture;
  
  float opacity = material.opacity;
  if (!is_null_texture(opacityTexture)) {
    if (params.alphaBlending) {
      opacity = opacityTexture.sample(textureSampler, in.uv).r;
    }
    if (params.alphaTesting) {
      opacity = opacityTexture.sample(textureSampler, in.uv).r;
      if (opacity < 0.2) {
        discard_fragment();
        return(0);
      }
    }
  }

  if (!is_null_texture(baseColorTexture)) {
    float4 color = baseColorTexture.sample(
      textureSampler,
      in.uv * params.tiling);
    material.baseColor = color.rgb;
  }

  // extract metallic
  if (!is_null_texture(metallicTexture)) {
    material.metallic = metallicTexture.sample(textureSampler, in.uv).r;
  }
  // extract roughness
  if (!is_null_texture(roughnessTexture)) {
    material.roughness = roughnessTexture.sample(textureSampler, in.uv).r;
  }
  // extract ambient occlusion
  if (!is_null_texture(aoTexture)) {
    material.ambientOcclusion = aoTexture.sample(textureSampler, in.uv).r;
  }
  // normal map
  float3 normal;
  if (is_null_texture(normalTexture)) {
    normal = in.worldNormal;
  } else {
    float3 normalValue = normalTexture.sample(
      textureSampler,
      in.uv * params.tiling).xyz * 2.0 - 1.0;
    normal = float3x3(
      in.worldTangent,
      in.worldBitangent,
      in.worldNormal) * normalValue;
  }
  normal = normalize(normal);
  float3 viewDirection = normalize(params.cameraPosition);
  float3 specularColor = 0;
  float3 diffuseColor = 0;
  for (uint i = 0; i < params.lightCount; i++) {
    Light light = lights[i];
    if (light.type == Ambient) {
      diffuseColor += material.baseColor * light.color;
      continue;
    }
    float3 lightDirection = normalize(light.position);
    float3 F0 = mix(0.04, material.baseColor, material.metallic);
  
    specularColor +=
      saturate(computeSpecular(
        normal,
        viewDirection,
        lightDirection,
        material.roughness,
        F0));

    diffuseColor +=
      saturate(computeDiffuse(
        material,
        normal,
        lightDirection) * light.color);
  }
  // shadow calculation
  diffuseColor *= calculateShadow(in.shadowPosition, shadowTexture);
  float4 color = float4(diffuseColor * opacity + specularColor, opacity);
  return color;
}

float G1V(float nDotV, float k)
{
  return 1.0f / (nDotV * (1.0f - k) + k);
}

// specular optimized-ggx
// AUTHOR John Hable. Released into the public domain
float3 computeSpecular(
    float3 normal,
    float3 viewDirection,
    float3 lightDirection,
    float roughness,
    float3 F0) {
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

// diffuse
float3 computeDiffuse(
  Material material,
  float3 normal,
  float3 lightDirection)
{
  float nDotL = saturate(dot(normal, lightDirection));
  float3 diffuse = float3(((1.0/pi) * material.baseColor) * (1.0 - material.metallic));
  diffuse = float3(material.baseColor) * (1.0 - material.metallic);
  return diffuse * nDotL * material.ambientOcclusion;
}
