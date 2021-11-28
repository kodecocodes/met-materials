/// Copyright (c) 2021 Razeware LLC
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

/*
 PBR.metal rendering equation from Apple's LODwithFunctionSpecialization sample code is under Copyright © 2021 Apple Inc.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#include <metal_stdlib>
using namespace metal;

#import "Common.h"

constant float pi = 3.1415926535897932384626433832795;

struct VertexOut {
  float4 position [[position]];
  float2 uv;
  float3 color;
  float3 worldPosition;
  float3 worldNormal;
  float3 worldTangent;
  float3 worldBitangent;
};

typedef struct Lighting {
  float3 lightDirection;
  float3 viewDirection;
  float3 normal;
  float3 lightColor;
} Lighting;

struct LightingParameters
{
  float3  lightDir;
  float3  viewDir;
  float3  halfVector;
  float3  reflectedVector;
  float3  normal;
  float3  reflectedColor;
  float3  irradiatedColor;
  float4  baseColor;
  float   nDoth;
  float   nDotv;
  float   nDotl;
  float   hDotl;
  float   metalness;
  float   roughness;
  float   ambientOcclusion;
};

// functions
LightingParameters calculateParameters(VertexOut in, Lighting lighting, Material material) ;
float3 computeSpecular(LightingParameters parameters);
float3 computeDiffuse(LightingParameters parameters);

fragment float4 fragment_PBR(VertexOut in [[stage_in]],
                             constant Params &params [[buffer(BufferIndexParams)]],
                             constant Light *lights [[buffer(2)]],
                             constant Material &_material [[buffer(BufferIndexMaterials)]],
                             texture2d<float> baseColorTexture [[texture(BaseColorTexture)]],
                             texture2d<float> normalTexture [[texture(NormalTexture)]],
                             texture2d<float> roughnessTexture [[texture(2)]],
                             texture2d<float> metallicTexture [[texture(3)]],
                             texture2d<float> aoTexture [[texture(4)]]){
  
  constexpr sampler textureSampler(
    filter::linear,
    address::repeat,
    mip_filter::linear,
    max_anisotropy(8));
  
  Material material = _material;
  
  // extract color
  if (!is_null_texture(baseColorTexture)) {
    material.baseColor = baseColorTexture.sample(
      textureSampler,
      in.uv * params.tiling).rgb;
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

  float3 viewDirection = normalize(params.cameraPosition - in.worldPosition);
  
  Light light = lights[0];
  float3 lightDirection = normalize(light.position);
  
  // all the necessary components are in place
  Lighting lighting;
  lighting.lightDirection = lightDirection;
  lighting.viewDirection = viewDirection;
  lighting.normal = normal;
  lighting.lightColor = light.color;
  
  LightingParameters parameters = calculateParameters(in, lighting, material);
  float3 specularColor = computeSpecular(parameters);
  float3 diffuseColor = computeDiffuse(parameters);

  return float4(specularColor + diffuseColor, 1);
}


LightingParameters calculateParameters(VertexOut in, Lighting lighting, Material material) {
  LightingParameters parameters;
  
  parameters.baseColor = float4(material.baseColor, 1);
  parameters.normal = lighting.normal;
  parameters.viewDir = lighting.viewDirection;
  parameters.roughness = material.roughness;
  parameters.metalness = material.metallic;
  parameters.ambientOcclusion = material.ambientOcclusion;
  
  parameters.lightDir = lighting.lightDirection;
  
  parameters.nDotl = max(0.001, saturate(dot(parameters.normal, parameters.lightDir)));
  parameters.halfVector = normalize(parameters.lightDir + parameters.viewDir);
  parameters.nDoth = max(0.001, saturate(dot(parameters.normal, parameters.halfVector)));
  parameters.nDotv = max(0.001, saturate(dot(parameters.normal, parameters.viewDir)));
  parameters.hDotl = max(0.001, saturate(dot(parameters.lightDir, parameters.halfVector)));
  
  parameters.irradiatedColor = float3(1);
  return parameters;
}

inline float sqr(float a) {
  return a * a;
}

// Specular
float Geometry(float Ndotv, float alphaG) {
  float a = alphaG * alphaG;
  float b = Ndotv * Ndotv;
  return (float)(1.0 / (Ndotv + sqrt(a + b - a*b)));
}

float Distribution(float NdotH, float roughness) {
  if (roughness >= 1.0)
    return 1.0 / pi;
  
  float roughnessSqr = roughness * roughness;
  
  float d = (NdotH * roughnessSqr - NdotH) * NdotH + 1;
  return roughnessSqr / (pi * d * d);
}

inline float Fresnel(float dotProduct) {
  return pow(clamp(1.0 - dotProduct, 0.0, 1.0), 5.0);
}


float3 computeSpecular(LightingParameters parameters)
{
  float specularRoughness = parameters.roughness * (1.0 - parameters.metalness) + parameters.metalness;
  float Ds = Distribution(parameters.nDoth, specularRoughness);
  Ds = Distribution(parameters.nDotl, specularRoughness);
  
  //  return parameters.halfVector;
  float3 Cspec0 = float3(1.0f);
  float3 Fs = float3(mix(float3(Cspec0), float3(1), Fresnel(parameters.hDotl)));
  float alphaG = sqr(specularRoughness * 0.5 + 0.5);
  float Gs = Geometry(parameters.nDotl, alphaG) * Geometry(parameters.nDotv, alphaG);
  
  float3 specularOutput = (Ds * Gs * Fs * parameters.irradiatedColor) * (1.0 + parameters.metalness * float3(parameters.baseColor))
    + float3(parameters.metalness) * parameters.irradiatedColor * float3(parameters.baseColor);
  
  return specularOutput * parameters.ambientOcclusion;
}


// diffuse
float3 computeDiffuse(LightingParameters parameters)
{
  float3 diffuseRawValue = float3(((1.0/pi) * parameters.baseColor) * (1.0 - parameters.metalness));
  diffuseRawValue = float3(parameters.baseColor) * (1.0 - parameters.metalness);
  return diffuseRawValue * parameters.nDotl * parameters.ambientOcclusion;
}
