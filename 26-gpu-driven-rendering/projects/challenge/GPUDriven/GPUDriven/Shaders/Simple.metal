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
#import "Common.h"
#import "Lighting.h"
#import "Material.h"

struct VertexOut {
  float4 position [[position]];
  float2 uv;
  uint modelIndex [[flat]];
};

vertex VertexOut vertex_simple(
  constant float3 *positions [[buffer(PositionBuffer)]],
  constant float2 *uvs [[buffer(UVBuffer)]],
  constant Uniforms &uniforms [[buffer(UniformsBuffer)]],
  constant ModelParams *modelParamsArray [[buffer(ModelParamsBuffer)]],
  constant uint &modelIndex [[buffer(SubmeshesArrayBuffer)]],
  uint baseInstance [[base_instance]],
  uint vertexId [[vertex_id]])
{
  ModelParams modelParams = modelParamsArray[modelIndex];
  float4 position = float4(positions[vertexId], 1);
  VertexOut out {
    .position = uniforms.projectionMatrix * uniforms.viewMatrix
                  * modelParams.modelMatrix * position,
    .uv = uvs[vertexId],
    .modelIndex = modelIndex
  };
  return out;
}


fragment float4 fragment_simple(
  VertexOut in [[stage_in]],
  constant Params &params [[buffer(ParamsBuffer)]],
  constant ModelParams *modelParamsArray [[buffer(ModelParamsBuffer)]],
  constant ShaderMaterial &shaderMaterial [[buffer(MaterialBuffer)]])
{
  constexpr sampler textureSampler(
    filter::linear,
    address::repeat,
    mip_filter::linear);

  ModelParams modelParams = modelParamsArray[in.modelIndex];
  Material material = shaderMaterial.material;
  texture2d<float> baseColorTexture = shaderMaterial.baseColorTexture;
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

  return float4(material.baseColor, 1);
}
