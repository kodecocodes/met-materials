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

float calc_distance(
  float3 pointA, float3 pointB,
  float3 camera_position,
  float4x4 modelMatrix)
{
  float3 positionA = (modelMatrix * float4(pointA, 1)).xyz;
  float3 positionB = (modelMatrix * float4(pointB, 1)).xyz;
  float3 midpoint = (positionA + positionB) * 0.5;

  float camera_distance = distance(camera_position, midpoint);
  return camera_distance;
}

kernel void
  tessellation_main(
    constant float *edge_factors [[buffer(0)]],
    constant float *inside_factors [[buffer(1)]],
    device MTLQuadTessellationFactorsHalf
      *factors [[buffer(2)]],
    constant float4 &camera_position [[buffer(3)]],
    constant float4x4 &modelMatrix   [[buffer(4)]],
    constant float3* control_points  [[buffer(5)]],
    constant Terrain &terrain        [[buffer(6)]],
    uint pid [[thread_position_in_grid]])
{
  uint index = pid * 4;
  float totalTessellation = 0;
  for (int i = 0; i < 4; i++) {
    int pointAIndex = i;
    int pointBIndex = i + 1;
    if (pointAIndex == 3) {
      pointBIndex = 0;
    }
    int edgeIndex = pointBIndex;
    float cameraDistance =
      calc_distance(
        control_points[pointAIndex + index],
        control_points[pointBIndex + index],
        camera_position.xyz,
        modelMatrix);
    float tessellation =
      max(4.0, terrain.maxTessellation / cameraDistance);
    factors[pid].edgeTessellationFactor[edgeIndex] = tessellation;
    totalTessellation += tessellation;
  }
  factors[pid].insideTessellationFactor[0] =
    totalTessellation * 0.25;
  factors[pid].insideTessellationFactor[1] =
    totalTessellation * 0.25;
}
