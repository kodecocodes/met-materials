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

fragment float4 fragment_IBL(
  FragmentIn in [[stage_in]],
  constant Params &params [[buffer(ParamsBuffer)]],
  constant Material &_material [[buffer(MaterialBuffer)]],
  texture2d<float> baseColorTexture [[texture(BaseColor)]],
  texture2d<float> normalTexture [[texture(NormalTexture)]],
  texture2d<float> roughnessTexture [[texture(RoughnessTexture)]],
  texture2d<float> metallicTexture [[texture(MetallicTexture)]],
  texture2d<float> aoTexture [[texture(AOTexture)]],
  texture2d<float> opacityTexture [[texture(OpacityTexture)]],
  depth2d<float> shadowTexture [[texture(ShadowTexture)]],
  texturecube<float> skybox [[texture(SkyboxTexture)]],
  texturecube<float> skyboxDiffuse [[texture(SkyboxDiffuseTexture)]],
  texture2d<float> brdfLut [[texture(BRDFLutTexture)]])
{
  constexpr sampler textureSampler(
    filter::linear,
    address::repeat,
    mip_filter::linear);
  
  Material material = _material;
  if (!is_null_texture(baseColorTexture)) {
    float4 color = baseColorTexture.sample(
      textureSampler,
      in.uv * params.tiling);
    material.baseColor = color.rgb;
  }

  float opacity = material.opacity;
  if (params.alphaBlending) {
    if (!is_null_texture(opacityTexture)) {
      opacity = opacityTexture.sample(textureSampler, in.uv).r;
    }
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
  
  float4 color = float4(material.baseColor, 1);

  float3 viewDirection =
    in.worldPosition.xyz - params.cameraPosition;
  viewDirection = normalize(viewDirection);
  float3 textureCoordinates =
    reflect(viewDirection, normal);

  float4 diffuse = skyboxDiffuse.sample(textureSampler, normal);
  diffuse = mix(pow(diffuse, 0.2), diffuse, material.metallic);
  diffuse *= calculateShadow(in.shadowPosition, shadowTexture);

  color = diffuse * float4(material.baseColor, 1);

  constexpr sampler s(filter::linear, mip_filter::linear);
  float3 prefilteredColor = skybox.sample(
    s,
    textureCoordinates,
    level(material.roughness * 10)).rgb;
  // 3
  float nDotV = saturate(dot(normal, -viewDirection));
  float2 envBRDF = brdfLut.sample(
    s,
    float2(material.roughness, nDotV)).rg;
  float3 f0 = mix(0.04, material.baseColor.rgb, material.metallic);
  float3 specularIBL = f0 * envBRDF.r + envBRDF.g;
  float3 specular = prefilteredColor * specularIBL;
  color += float4(specular, 1);
  color *= material.ambientOcclusion;
  return color;
}
