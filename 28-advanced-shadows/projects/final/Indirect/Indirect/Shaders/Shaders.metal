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
#import "Common.h"

struct VertexIn {
  float4 position [[attribute(Position)]];
  float3 normal [[attribute(Normal)]];
  float2 uv [[attribute(UV)]];
};

struct VertexOut {
  float4 position [[position]];
  float2 uv;
};

vertex VertexOut vertex_main(
  const VertexIn in [[stage_in]],
  constant Uniforms &uniforms [[buffer(UniformsBuffer)]],
  constant ModelParams &modelParams [[buffer(ModelParamsBuffer)]])
{
  float4 position = in.position;
  VertexOut out {
    .position = uniforms.projectionMatrix * uniforms.viewMatrix
    * modelParams.modelMatrix * position,
      .uv = in.uv,
  };
  return out;
}

fragment float4 fragment_main(
  constant ModelParams &modelParams [[buffer(ModelParamsBuffer)]],
  VertexOut in [[stage_in]],
  constant ShaderMaterial &shaderMaterial [[buffer(MaterialBuffer)]])
{
  constexpr sampler textureSampler(address::repeat);
  
  Material material = shaderMaterial.material;
  auto textures = shaderMaterial.textures;
  texture2d<float> baseColorTexture = textures[BaseColor];
  texture2d<float> opacityTexture = textures[OpactityTexture];
  material.baseColor = baseColorTexture.sample(
    textureSampler,
    in.uv * modelParams.tiling).rgb;
  if (!is_null_texture(opacityTexture)) {
    material.opacity = opacityTexture.sample(textureSampler, in.uv).r;
  }
  return float4(material.baseColor, material.opacity);
}
