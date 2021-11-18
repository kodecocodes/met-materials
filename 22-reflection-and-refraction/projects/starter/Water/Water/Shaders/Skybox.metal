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
};

struct VertexOut {
  float4 position [[ position ]];
  float4 uv;
};

struct FragmentIn {
  float4 position [[ position ]];
  float4 uv;
};

vertex VertexOut vertex_skybox(const VertexIn vertex_in [[stage_in]],
                               constant Uniforms &uniforms [[ buffer(BufferIndexUniforms) ]]) {
  VertexOut vertex_out;
  float4x4 mvp = uniforms.projectionMatrix * uniforms.skyboxViewMatrix * uniforms.modelMatrix;
  vertex_out.position = (mvp * vertex_in.position).xyww;
  vertex_out.uv = vertex_in.position;
  return vertex_out;
}

fragment half4 fragment_skybox(FragmentIn vertex_in [[stage_in]],
                               texturecube<half> cube_texture [[texture(0)]]) {
  constexpr sampler default_sampler;
  float3 uv = vertex_in.uv.xyz;
  half4 color = cube_texture.sample(default_sampler, uv);
  return color;
}
