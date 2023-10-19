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

struct VertexIn {
  packed_float3 position;
  packed_float3 normal;
  float2 uv;
};

struct VertexOut {
  float4 position [[position]];
  float3 worldPosition;
  float3 worldNormal;
  float2 uv;
  uint textureID [[flat]];
};

vertex VertexOut vertex_nature(
  constant VertexIn *in [[buffer(0)]],
  uint vertexID [[vertex_id]],
  constant int &vertexCount [[buffer(1)]],
  constant Uniforms *uniforms [[buffer(UniformsBuffer)]],
  constant ModelTransform *model [[buffer(ModelTransformBuffer)]],
  constant NatureInstance *instances [[buffer(InstancesBuffer)]],
  uint instanceID [[instance_id]])
{
  NatureInstance instance = instances[instanceID];
  uint offset = instance.morphTargetID * vertexCount;
  VertexIn vertexIn = in[vertexID + offset];

  VertexOut out;
  float4 position = float4(vertexIn.position, 1);
  float3 normal = vertexIn.normal;

  out.position = uniforms->projectionMatrix * uniforms->viewMatrix
  * model->modelMatrix * instance.modelMatrix * position;
  out.worldPosition = (model->modelMatrix * position
                       * instance.modelMatrix).xyz;
  out.worldNormal = model->normalMatrix * instance.normalMatrix * normal;
  out.uv = vertexIn.uv;
  out.textureID = instance.textureID;
  return out;
}

constant float3 sunlight = float3(2, 4, -4);

fragment float4 fragment_nature(
  VertexOut in [[stage_in]],
  texture2d_array<float> baseColorTexture [[texture(0)]],
  constant Params &params [[buffer(ParamsBuffer)]])
{
  constexpr sampler s(
    filter::linear,
    address::repeat,
    mip_filter::linear,
    max_anisotropy(8));
  float4 baseColor = baseColorTexture.sample(s, in.uv, in.textureID);
  float3 normal = normalize(in.worldNormal);

  float3 lightDirection = normalize(sunlight);
  float diffuseIntensity = saturate(dot(lightDirection, normal));
  float4 color = mix(baseColor*0.5, baseColor*1.5, diffuseIntensity);
  return color;
}

vertex float4 vertex_nature_depth(
  constant VertexIn *in [[buffer(0)]],
  uint vertexID [[vertex_id]],
  constant int &vertexCount [[buffer(1)]],
  constant Uniforms *uniforms [[buffer(UniformsBuffer)]],
  constant ModelTransform *model [[buffer(ModelTransformBuffer)]],
  constant NatureInstance *instances [[buffer(InstancesBuffer)]],
  uint instanceID [[instance_id]])
{
  NatureInstance instance = instances[instanceID];
  uint offset = instance.morphTargetID * vertexCount;
  VertexIn vertexIn = in[vertexID + offset];

  float4 position = float4(vertexIn.position, 1);

  position = uniforms->shadowProjectionMatrix * uniforms->shadowViewMatrix
  * model->modelMatrix * instance.modelMatrix * position;
  return position;
}
