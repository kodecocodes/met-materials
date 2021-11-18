//
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

constant bool hasSkeleton [[function_constant(5)]];

struct VertexIn {
  float4 position [[attribute(Position)]];
  float3 normal [[attribute(Normal)]];
  float2 uv [[attribute(UV)]];
  float3 tangent [[attribute(Tangent)]];
  float3 bitangent [[attribute(Bitangent)]];
  ushort4 joints [[attribute(Joints)]];
  float4 weights [[attribute(Weights)]];
};

struct VertexOut {
  float4 position [[position]];
  float3 worldPosition;
  float3 worldNormal;
  float3 worldTangent;
  float3 worldBitangent;
  float2 uv;
};

vertex VertexOut vertex_main(const VertexIn vertexIn [[stage_in]],
                             constant float4x4 *jointMatrices [[buffer(22),
                                                                function_constant(hasSkeleton)]],
                             constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]])

{
  float4 position = vertexIn.position;
  float4 normal = float4(vertexIn.normal, 0);
  float4 tangent = float4(vertexIn.tangent, 0);
  float4 bitangent = float4(vertexIn.bitangent, 0);
  
  if (hasSkeleton) {
    float4 weights = vertexIn.weights;
    ushort4 joints = vertexIn.joints;
    position =
    weights.x * (jointMatrices[joints.x] * position) +
    weights.y * (jointMatrices[joints.y] * position) +
    weights.z * (jointMatrices[joints.z] * position) +
    weights.w * (jointMatrices[joints.w] * position);
    normal =
    weights.x * (jointMatrices[joints.x] * normal) +
    weights.y * (jointMatrices[joints.y] * normal) +
    weights.z * (jointMatrices[joints.z] * normal) +
    weights.w * (jointMatrices[joints.w] * normal);
    tangent =
    weights.x * (jointMatrices[joints.x] * tangent) +
    weights.y * (jointMatrices[joints.y] * tangent) +
    weights.z * (jointMatrices[joints.z] * tangent) +
    weights.w * (jointMatrices[joints.w] * tangent);
    bitangent =
    weights.x * (jointMatrices[joints.x] * bitangent) +
    weights.y * (jointMatrices[joints.y] * bitangent) +
    weights.z * (jointMatrices[joints.z] * bitangent) +
    weights.w * (jointMatrices[joints.w] * bitangent);
  }
  
  VertexOut out {
    .position = uniforms.projectionMatrix * uniforms.viewMatrix 
    * uniforms.modelMatrix * position,
    .worldPosition = (uniforms.modelMatrix * position).xyz,
    .worldNormal = uniforms.normalMatrix * normal.xyz,
    .worldTangent = uniforms.normalMatrix * tangent.xyz,
    .worldBitangent = uniforms.normalMatrix * bitangent.xyz,
    .uv = vertexIn.uv
  };

  return out;
}

fragment float4 skyboxTest(VertexOut in [[stage_in]],
                           constant FragmentUniforms &fragmentUniforms
                           [[buffer(BufferIndexFragmentUniforms)]],
                           texturecube<float> skybox [[texture(BufferIndexSkybox)]]) {
  float3 viewDirection = in.worldPosition.xyz -
  fragmentUniforms.cameraPosition;
  float3 textureCoordinates = reflect(viewDirection, in.worldNormal);
  constexpr sampler defaultSampler(filter::linear);
  float4 color = skybox.sample(defaultSampler, textureCoordinates);
  float4 copper = float4(0.86, 0.7, 0.48, 1);
  color = color * copper;
  return color;
}

