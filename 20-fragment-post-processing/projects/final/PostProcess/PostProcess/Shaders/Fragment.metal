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
#import "ShaderDefs.h"

float calculateShadow(
  float4 shadowPosition,
  depth2d<float> shadowTexture);

float4 fog(float4 position, float4 color) {
  float distance = position.z / position.w;
  float density = 0.2;
  float fog = 1.0 - clamp(exp(-density * distance), 0.0, 1.0);
  float4 fogColor = float4(1.0);
  color = mix(color, fogColor, fog);
  return color;
}

fragment float4 fragment_main(
  constant Params &params [[buffer(ParamsBuffer)]],
  VertexOut in [[stage_in]],
  constant Light *lights [[buffer(LightBuffer)]],
  constant Material &_material [[buffer(MaterialBuffer)]],
  texture2d<float> baseColorTexture [[texture(BaseColor)]],
  texture2d<float> normalTexture [[texture(NormalTexture)]],
  texture2d<float> roughnessTexture [[texture(RoughnessTexture)]],
  texture2d<float> metallicTexture [[texture(MetallicTexture)]],
  texture2d<float> aoTexture [[texture(AOTexture)]],
  texture2d<float> opacityTexture [[texture(OpacityTexture)]],
  depth2d<float> shadowTexture [[texture(ShadowTexture)]])
{
  constexpr sampler textureSampler(
    filter::linear,
    mip_filter::linear,
    address::repeat);

  Material material = _material;

  if (!is_null_texture(baseColorTexture)) {
    float4 color = baseColorTexture.sample(
      textureSampler,
      in.uv * params.tiling);
    if (params.alphaTesting && color.a < 0.1) {
      discard_fragment();
      return 0;
    }
    material.baseColor = color.rgb;
  }

  if (params.alphaBlending) {
    if (!is_null_texture(opacityTexture)) {
      material.opacity =
        opacityTexture.sample(textureSampler, in.uv).r;
    }
  }

  if (!is_null_texture(roughnessTexture)) {
    material.roughness = roughnessTexture.sample(
      textureSampler,
      in.uv * params.tiling).r;
  }

  if (!is_null_texture(metallicTexture)) {
    material.metallic = metallicTexture.sample(
      textureSampler,
      in.uv * params.tiling).r;
  }

  if (!is_null_texture(aoTexture)) {
    material.ambientOcclusion = aoTexture.sample(
      textureSampler,
      in.uv * params.tiling).r;
  }

  float3 normal;
  if (is_null_texture(normalTexture)) {
    normal = in.worldNormal;
  } else {
    normal = normalTexture.sample(
    textureSampler,
    in.uv * params.tiling).rgb;
    normal = normal * 2 - 1;
    normal = float3x3(
      in.worldTangent,
      in.worldBitangent,
      in.worldNormal) * normal;
  }
  normal = normalize(normal);

  float3 diffuseColor =
    computeDiffuse(lights, params, material, normal);

  float3 specularColor =
    computeSpecular(
      lights,
      params,
      material,
      normal);

  float shadow = calculateShadow(in.shadowPosition, shadowTexture);
  diffuseColor *= shadow;

  float4 color =
    float4(diffuseColor + specularColor, material.opacity);
  if (params.fog) {
    color = fog(in.position, color);
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
