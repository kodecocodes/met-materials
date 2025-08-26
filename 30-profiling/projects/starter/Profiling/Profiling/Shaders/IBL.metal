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
#include "Lighting.h"
#include "ShaderDefs.h"

fragment float4 fragment_IBL(
  VertexOut in [[stage_in]],
  constant Params &params [[buffer(ParamsBuffer)]],
  constant Light *lights [[buffer(LightBuffer)]],
  constant ShaderMaterial &shaderMaterial [[buffer(MaterialBuffer)]],
  depth2d<float> shadowTexture [[texture(ShadowTexture)]],
  texturecube<float> skybox [[texture(SkyboxTexture)]],
  texturecube<float> skyboxDiffuse [[texture(SkyboxDiffuseTexture)]],
  texture2d<float> brdfLut [[texture(BRDFLutTexture)]])
{
  // Load the materials from textures
  constexpr sampler textureSampler(
    filter::linear,
    mip_filter::linear,
    address::repeat);
  Material material = shaderMaterial.material;
  auto textures = shaderMaterial.textures;
  texture2d<float> baseColorTexture = textures[BaseColor];
  texture2d<float> normalTexture = textures[NormalTexture];
  texture2d<float> metallicTexture = textures[MetallicTexture];
  texture2d<float> roughnessTexture = textures[RoughnessTexture];
  texture2d<float> aoTexture = textures[AOTexture];
  texture2d<float> opacityTexture = textures[OpacityTexture];
  float2 uv = in.uv * params.tiling;
  if (!is_null_texture(baseColorTexture)) {
    float4 color = baseColorTexture.sample(textureSampler, uv);
    material.baseColor = color.rgb;
    material.opacity = color.a;
  }
  if (params.alphaBlending) {
    if (!is_null_texture(opacityTexture)) {
      material.opacity = opacityTexture.sample(textureSampler, uv).r;
    }
  }
  if (!is_null_texture(roughnessTexture)) {
    material.roughness = roughnessTexture.sample( textureSampler, uv).r;
  }
  material.roughness = clamp(material.roughness, 0.02, 1.0);
  if (!is_null_texture(metallicTexture)) {
    material.metallic = metallicTexture.sample(textureSampler, uv).r;
  }
  material.metallic = clamp(material.metallic, 0.0, 1.0);
  if (!is_null_texture(aoTexture)) {
    material.ambientOcclusion = aoTexture.sample(textureSampler, uv).r;
  }
  material.ambientOcclusion = clamp(material.ambientOcclusion, 0.0, 1.0);
  
  float3 normal;
  if (is_null_texture(normalTexture)) {
    normal = in.worldNormal;
  } else {
    normal = normalTexture.sample(textureSampler, uv).rgb;
    normal = normal * 2.0 - 1.0;
    normal = float3x3(
      normalize(in.worldTangent),
      normalize(in.worldBitangent),
      normalize(in.worldNormal)) * normalize(normal);
  }
  normal = normalize(normal);
  
  float3 viewDirection = params.cameraPosition - in.worldPosition.xyz;
  viewDirection = normalize(viewDirection);
  float3 textureCoordinates = reflect(-viewDirection, normal);
  float NdotV = saturate(dot(normal, viewDirection));
  
  float3 F0 = mix(float3(0.04), material.baseColor.rgb, material.metallic);

  float3 diffuseIrradiance = skyboxDiffuse.sample(textureSampler, normal).rgb;
  float3 diffuse = diffuseIrradiance * material.baseColor.rgb * (1.0 - material.metallic);
  
  diffuse *= material.ambientOcclusion;
  
  constexpr float specularMipCount = 5.0;
  float lod = material.roughness * specularMipCount;
  
  float3 prefiltered = skybox.sample(textureSampler, textureCoordinates, level(lod)).rgb;
  float2 brdf = brdfLut.sample(textureSampler, float2(material.roughness, NdotV)).rg;
  float3 specular = prefiltered * (F0 * brdf.x + brdf.y);

  float shadow = calculateSoftShadow(in.shadowPosition, shadowTexture);
  diffuse *= shadow;

  float3 color = diffuse + specular;
  return float4(color, material.opacity);
}
