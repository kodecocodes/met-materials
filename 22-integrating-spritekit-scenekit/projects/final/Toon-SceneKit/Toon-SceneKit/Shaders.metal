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

#include <SceneKit/scn_metal>

struct VertexIn {
  float4 position [[attribute(SCNVertexSemanticPosition)]];
  float3 normal [[attribute(SCNVertexSemanticNormal)]];
  float2 uv [[attribute(SCNVertexSemanticTexcoord0)]];

};

struct Uniforms {
  float4x4 modelViewProjectionTransform;
  float4x4 normalTransform;
  float4x4 modelViewTransform;
};

struct VertexOut {
  float4 position [[position]];
  float2 uv;
  float3 normal;
  float4 viewLightPosition;
  float4 viewPosition;
};

vertex VertexOut shipVertex(VertexIn in [[stage_in]],
                            constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                            constant float3& lightPosition [[buffer(2)]],
                            constant Uniforms& scn_node [[buffer(1)]])
{
  VertexOut out;
  out.position = scn_node.modelViewProjectionTransform * in.position;
  out.uv = in.uv;
  out.normal = (scn_node.normalTransform * float4(in.normal, 0)).xyz;
  out.viewLightPosition = scn_frame.viewTransform * float4(lightPosition, 1);
  out.viewPosition = scn_node.modelViewTransform * in.position;

  return out;
}

fragment half4 shipFragment(VertexOut in [[stage_in]],
                            texture2d<float> baseColorTexture [[texture(0)]])
{
  float3 v = normalize(float3(0, 0, 10)); // camera position
  float3 n = normalize(in.normal);
  float edge = step(fwidth(dot(v, n)) * 10.0, 0.4);
  if (edge < 1.0) {
    return edge;
  }
  float3 l =
  (normalize(in.viewLightPosition - in.viewPosition)).xyz;
  float diffuseIntensity = saturate(dot(n, l));
  float i = diffuseIntensity * 10.0;
  i = floor(i) - fmod(floor(i), 2);
  i *= 0.1;
  half4 color = half4(0, 1, 1, 1);
  float specular = pow(max(0.0, dot(reflect(-l, n), v)), 5.0);
  if (specular > 0.5) {
    return 1.0;
  }
  return color * pow(i, 4) * 4;
  
  
  
}



