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

#import "ShaderDefs.h"
#import "Lighting.h"
#import "Material.h"

fragment float4 fragment_main(
  VertexOut in [[stage_in]],
  constant Params &params [[buffer(ParamsBuffer)]],
  constant ModelParams &modelParams [[buffer(ModelParamsBuffer)]],
  constant Light *lights [[buffer(LightBuffer)]],
  constant ShaderMaterial &shaderMaterial [[buffer(MaterialBuffer)]])
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
                                           in.uv * modelParams.tiling);
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
                                              in.uv * modelParams.tiling).xyz * 2.0 - 1.0;
    normal = in.worldNormal * normalValue;
  }
  normal = normalize(normal);
  
  float3 diffuseColor = 0;
  for (uint i = 0; i < params.lightCount; i++) {
    Light light = lights[i];
    if (light.type == Ambient) {
      diffuseColor += material.baseColor * light.color;
      continue;
    }
  }
  diffuseColor +=
      computeDiffuse(lights, params, material, normal);

    float3 specularColor =
      computeSpecular(lights, params, material, normal);


  float4 color = float4(diffuseColor * opacity + specularColor, opacity);
  return color;
}
