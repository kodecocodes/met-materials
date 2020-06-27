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

struct VertexIn {
  float4 position [[ attribute(0) ]];
  float3 normal [[ attribute(1) ]];
  float2 uv [[ attribute(2) ]];
};

struct VertexOut {
  float4 position [[ position ]];
  float3 worldNormal;
  float3 worldPosition;
  float2 uv;
};

struct FragmentIn {
  float4 position [[ position ]];
  float3 worldNormal;
  float3 worldPosition;
  float2 uv;
};

vertex VertexOut vertex_main(const VertexIn vertex_in [[ stage_in ]],
                             constant Uniforms &uniforms [[ buffer(BufferIndexUniforms) ]]) {
  VertexOut vertex_out;
  float4x4 mvp = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix;
  vertex_out.position = mvp * vertex_in.position;
  vertex_out.worldNormal = uniforms.normalMatrix * vertex_in.normal;
  vertex_out.uv = vertex_in.uv;
  vertex_out.worldPosition = (uniforms.modelMatrix *
                              vertex_in.position).xyz;
  return vertex_out;
}

fragment float4 fragment_main(FragmentIn vertex_in [[ stage_in ]],
                              texture2d<float> texture [[ texture(0) ]]) {
  constexpr sampler default_sampler(filter::linear, address::repeat);
  float4 color = texture.sample(default_sampler, vertex_in.uv);
  float3 normal = normalize(vertex_in.worldNormal);
  float3 lightDirection = normalize(sunlight);
  float diffuseIntensity = saturate(dot(lightDirection, normal));
  color *= diffuseIntensity;
  return color;
}


fragment float4 fragment_terrain(FragmentIn vertex_in [[ stage_in ]],
                                 texture2d<float> texture [[ texture(0) ]],
                                 texture2d<float> underwaterTexture [[ texture(1) ]]) {
  constexpr sampler default_sampler(filter::linear, address::repeat);
  float4 color;
  float4 grass = texture.sample(default_sampler, vertex_in.uv * tiling);
  color = grass;
  
  // uncomment this for pebbles
  /*
  float4 underwater = underwaterTexture.sample(default_sampler,
                                               vertex_in.uv * tiling);
  float lower = -0.3;
  float upper = 0.2;
  float y = vertex_in.worldPosition.y;
  float waterHeight = (upper - y) / (upper - lower);
  vertex_in.worldPosition.y < lower ?
  (color = underwater) :
  (vertex_in.worldPosition.y > upper ?
   (color = grass) :
   (color = mix(grass, underwater, waterHeight))
   );
  */
  float3 normal = normalize(vertex_in.worldNormal);
  float3 lightDirection = normalize(sunlight);
  float diffuseIntensity = saturate(dot(lightDirection, normal));
  color *= diffuseIntensity;
  return color;
}
