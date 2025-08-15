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

struct VertexOut {
  float4 position [[position]];
  float4 color;
};

vertex VertexOut vertex_main(
  constant Vertex* vertexIn [[buffer(0)]],
  uint vertexID [[vertex_id]]) {
  Vertex in = vertexIn[vertexID];
  VertexOut out {
    .position = float4(in.x, in.y, in.z, 1),
    .color = float4(1, 0.2, 0, 1)
  };
  return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
  return in.color;
}

using Triangle = metal::mesh<
  VertexOut, void, 3, 1,
  metal::topology::triangle>;

[[mesh]] void mesh_main(
    Triangle triangle,
    uint threadID[[thread_index_in_threadgroup]])
{
  float4 positions[3] = {
      float4( 0.0,  0.5, 0.0, 1),
      float4(-0.5, -0.5, 0.0, 1),
      float4( 0.5, -0.5, 0.0, 1)
  };

  float4 colors[3] = {
      float4(1.0, 0.0, 0.0, 1.0),
      float4(0.0, 1.0, 0.0, 1.0),
      float4(0.0, 0.0, 1.0, 1.0)
  };

  if (threadID < 3) {
    triangle.set_vertex(threadID, VertexOut {
      .position = positions[threadID],
      .color = colors[threadID]
    });
    triangle.set_index(threadID, threadID);
  }
  if (threadID == 0) {
    triangle.set_primitive_count(1);
  }
}
