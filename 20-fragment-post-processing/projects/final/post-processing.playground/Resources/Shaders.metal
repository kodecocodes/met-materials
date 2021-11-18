/**
 * Copyright (c) 2018 Razeware LLC
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

struct VertexIn {
  float4 position [[attribute(0)]];
  float3 normal [[attribute(1)]];
  float2 uv [[attribute(2)]];
};

struct VertexOut {
  float4 position [[ position ]];
  float3 normal;
  float2 uv;
  float4 color;
};

vertex VertexOut vertex_main(const VertexIn vertex_in [[stage_in]],
                             constant float4x4 &mvp_matrix [[buffer(1)]])
{
  VertexOut vertex_out;
  vertex_out.position = mvp_matrix * vertex_in.position;
  vertex_out.uv = vertex_in.uv;
  return vertex_out;
}

float4 fog(float4 position, float4 color) {
  float distance = position.z / position.w;
  float density = 0.2;
  float fog = 1.0 - clamp(exp(-density * distance), 0.0, 1.0);
  float4 fogColor = float4(1.0);
  color = mix(color, fogColor, fog);
  return color;
}

fragment float4 fragment_main(VertexOut vertex_in [[stage_in]],
                              constant bool &fogEnabled [[buffer(1)]],
                              texture2d<float> texture [[texture(0)]])
{
  constexpr sampler s(filter::linear);
  float4 color = texture.sample(s, vertex_in.uv);
  if (fogEnabled) {
    color = fog(vertex_in.position, color);
  }
  return color;
}

vertex VertexOut vertex_light(const VertexIn vertex_in [[stage_in]],
                              constant float4x4 &mvp_matrix [[buffer(1)]])
{
  VertexOut vertex_out;
  vertex_out.position = mvp_matrix * vertex_in.position;
  vertex_out.uv = vertex_in.uv;
  
  vertex_out.normal = (mvp_matrix * float4(vertex_in.normal, 0)).xyz;
  float3 light_direction = {1.0, 1.0, -1.0};
  float4 light_color = float4(1.0);
  float intensity = dot(normalize(vertex_out.normal),
                        normalize(light_direction));
  vertex_out.color = saturate(light_color * intensity);
  
  return vertex_out;
}

fragment float4 fragment_tree(VertexOut vertex_in [[stage_in]],
                              texture2d<float> texture [[texture(0)]],
                              constant bool &fogEnabled [[buffer(1)]],
                              constant bool & transparencyEnabled [[buffer(0)]])
{
  constexpr sampler s(filter::linear);
  float4 color = texture.sample(s, vertex_in.uv);
  if (transparencyEnabled && color.a < 0.1) {
    discard_fragment();
  }
  color *= vertex_in.color * 2;
  if (fogEnabled) {
    color = fog(vertex_in.position, color);
  }
  return color;
}

fragment float4 fragment_window(VertexOut vertex_in [[stage_in]],
                                constant bool &fogEnabled [[buffer(1)]],
                                constant bool &blendingEnabled [[buffer(0)]],
                                texture2d<float> texture [[texture(0)]])
{
  constexpr sampler s(filter::linear);
  float4 color = texture.sample(s, vertex_in.uv);
  if (blendingEnabled) {
    color.a = 0.5;
  }
  if (fogEnabled) {
    color = fog(vertex_in.position, color);
  }
  return color;
}

