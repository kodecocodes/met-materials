/**
 * Copyright (c) 2019 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include <metal_stdlib>
using namespace metal;
#import "Common.h"

constant bool hasColorTexture [[function_constant(0)]];
constant bool hasNormalTexture [[function_constant(1)]];
constant bool hasRoughnessTexture [[function_constant(2)]];
constant bool hasMetallicTexture [[function_constant(3)]];
constant bool hasAOTexture [[function_constant(4)]];

struct VertexOut {
  float4 position [[position]];
  float3 worldPosition;
  float3 worldNormal;
  float2 uv;
  float3 worldTangent;
  float3 worldBitangent;
};

fragment float4 fragment_IBL(VertexOut in [[stage_in]],
                             sampler textureSampler [[sampler(0)]],
                             constant Material &material [[buffer(BufferIndexMaterials)]],
                             constant FragmentUniforms &fragmentUniforms [[buffer(BufferIndexFragmentUniforms)]],
                             texture2d<float> baseColorTexture [[texture(0), function_constant(hasColorTexture)]],
                             texture2d<float> normalTexture [[texture(1), function_constant(hasNormalTexture)]],
                             texture2d<float> roughnessTexture [[texture(2), function_constant(hasRoughnessTexture)]],
                             texture2d<float> metallicTexture [[texture(3), function_constant(hasMetallicTexture)]],
                             texture2d<float> aoTexture [[texture(4), function_constant(hasAOTexture)]],
                             texturecube<float> skybox [[texture(BufferIndexSkybox)]],
                             texturecube<float> skyboxDiffuse [[texture(BufferIndexSkyboxDiffuse)]],
                             texture2d<float> brdfLut [[texture(BufferIndexBRDFLut)]]
                             ){
  // extract color
  float3 baseColor;
  if (hasColorTexture) {
    baseColor = baseColorTexture.sample(textureSampler,
                                        in.uv * fragmentUniforms.tiling).rgb;
  } else {
    baseColor = material.baseColor;
  }
  // extract metallic
  float metallic;
  if (hasMetallicTexture) {
    metallic = metallicTexture.sample(textureSampler, in.uv).r;
  } else {
    metallic = material.metallic;
  }
  // extract roughness
  float roughness;
  if (hasRoughnessTexture) {
    roughness = roughnessTexture.sample(textureSampler, in.uv).r;
  } else {
    roughness = material.roughness;
  }
  // extract ambient occlusion
  float ambientOcclusion;
  if (hasAOTexture) {
    ambientOcclusion = aoTexture.sample(textureSampler, in.uv).r;
  } else {
    ambientOcclusion = 1.0;
  }
  
  // normal map
  float3 normal;
  if (hasNormalTexture) {
    float3 normalValue = normalTexture.sample(textureSampler, in.uv * fragmentUniforms.tiling).xyz * 2.0 - 1.0;
    normal = in.worldNormal * normalValue.z
    + in.worldTangent * normalValue.x
    + in.worldBitangent * normalValue.y;
    
  } else {
    normal = in.worldNormal;
  }
  normal = normalize(normal);
  float4 diffuse = skyboxDiffuse.sample(textureSampler, normal);
  diffuse = mix(pow(diffuse, 0.5), diffuse, metallic);

  float3 viewDirection = in.worldPosition.xyz -
  fragmentUniforms.cameraPosition;
  float3 textureCoordinates = reflect(viewDirection, normal);

  constexpr sampler s(filter::linear, mip_filter::linear);
  float3 prefilteredColor = skybox.sample(s, textureCoordinates,
                                          level(roughness * 10)).rgb;

  float nDotV = saturate(dot(normal, normalize(-viewDirection)));
  float2 envBRDF = brdfLut.sample(s, float2(roughness, nDotV)).rg;
  
  float3 f0 = mix(0.04, baseColor.rgb, metallic);
  float3 specularIBL = f0 * envBRDF.r + envBRDF.g;
  
  float3 specular = prefilteredColor * specularIBL;
  float4 color = diffuse * float4(baseColor, 1) + float4(specular, 1);
  color *= ambientOcclusion;

  return color;
  
}


