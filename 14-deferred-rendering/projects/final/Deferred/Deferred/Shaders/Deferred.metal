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

struct GBufferOut {
  float4 albedo [[color(RenderTargetAlbedo)]];
  float4 normal [[color(RenderTargetNormal)]];
  float4 position [[color(RenderTargetPosition)]];
};

fragment GBufferOut fragment_gBuffer(
  VertexOut in [[stage_in]],
  depth2d<float> shadowTexture [[texture(ShadowTexture)]],
  constant Material &material [[buffer(MaterialBuffer)]])
{
  GBufferOut out;
  out.albedo = float4(material.baseColor, 1.0);
  out.albedo.a = calculateShadow(in.shadowPosition, shadowTexture);
  out.normal = float4(normalize(in.worldNormal), 1.0);
  out.position = float4(in.worldPosition, 1.0);
  return out;
}

constant float3 vertices[6] = {
  float3(-1,  1,  0),    // triangle 1
  float3( 1, -1,  0),
  float3(-1, -1,  0),
  float3(-1,  1,  0),    // triangle 2
  float3( 1,  1,  0),
  float3( 1, -1,  0)
};

vertex VertexOut vertex_quad(uint vertexID [[vertex_id]])
{
  VertexOut out {
    .position = float4(vertices[vertexID], 1)
  };
  return out;
}

fragment float4 fragment_deferredSun(
  VertexOut in [[stage_in]],
  constant Params &params [[buffer(ParamsBuffer)]],
  constant Light *lights [[buffer(LightBuffer)]],
  texture2d<float> albedoTexture [[texture(BaseColor)]],
  texture2d<float> normalTexture [[texture(NormalTexture)]])
{
  uint2 coord = uint2(in.position.xy);
  float4 albedo = albedoTexture.read(coord);
  float3 normal = normalTexture.read(coord).xyz;
  Material material {
    .baseColor = albedo.xyz,
    .ambientOcclusion = 1.0
  };

  float3 color = 0;
  for (uint i = 0; i < params.lightCount; i++) {
    Light light = lights[i];
    color += calculateSun(light, normal, params, material);
  }
  color *= albedo.a;
  return float4(color, 1);
}

struct PointLightIn {
  float4 position [[attribute(Position)]];
};

struct PointLightOut {
  float4 position [[position]];
  uint instanceId [[flat]];
};

vertex PointLightOut vertex_pointLight(
  PointLightIn in [[stage_in]],
  constant Uniforms &uniforms [[buffer(UniformsBuffer)]],
  constant Light *lights [[buffer(LightBuffer)]],
  uint instanceId [[instance_id]])
{
  float4 lightPosition = float4(lights[instanceId].position, 0);
  float4 position =
    uniforms.projectionMatrix * uniforms.viewMatrix
    * (in.position + lightPosition);
  PointLightOut out {
    .position = position,
    .instanceId = instanceId
  };
  return out;
}

fragment float4 fragment_pointLight(
  PointLightOut in [[stage_in]],
  constant Params &params [[buffer(ParamsBuffer)]],
  texture2d<float> normalTexture [[texture(NormalTexture)]],
  texture2d<float> positionTexture
    [[texture(NormalTexture + 1)]],
  constant Light *lights [[buffer(LightBuffer)]])
{
  uint2 coords = uint2(in.position.xy);
  float3 normal = normalTexture.read(coords).xyz;
  float3 worldPosition = positionTexture.read(coords).xyz;
  Material material {
    .baseColor = 1
  };
  Light light = lights[in.instanceId];
  float3 color = calculatePoint(
    light,
    worldPosition,
    normal,
    material);
  color *= 0.5;
  return float4(color, 1);
}
