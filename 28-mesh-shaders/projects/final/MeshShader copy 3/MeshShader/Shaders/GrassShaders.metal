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
#import "ShaderDefs.h"

float randomNoise(float2 p) {
return fract(6791.0 * sin(47.0 * p.x + 9973.0 * p.y));
}

[[object]]
void object_grass(
  uint3 objectID [[threadgroup_position_in_grid]],
  constant GrassUniforms& uniforms [[buffer(GrassUniformsBuffer)]],
  constant GrassSettings& settings [[buffer(GrassSettingsBuffer)]],
  object_data GrassPayload& payload [[payload]],
  mesh_grid_properties meshGridProperties)
{
  float halfGrid = (settings.gridSize - 1.0) * 0.5;
  float3 tileCenter = float3(
    (float(objectID.x) - halfGrid) * settings.tileSize,
    0.0,
    (float(objectID.z) - halfGrid) * settings.tileSize
  );
  float distanceToCamera =
    length(uniforms.cameraPosition - tileCenter);
  uint bladesInTile;
  if (distanceToCamera < settings.maxDistance * 0.3) {
    bladesInTile = MaxBladesPerTile;
  } else if (distanceToCamera < settings.maxDistance * 0.6) {
    bladesInTile = MaxBladesPerTile / 2;
  } else if (distanceToCamera < settings.maxDistance) {
    bladesInTile = MaxBladesPerTile / 4;
  } else {
    bladesInTile = 0;
  }
  if (bladesInTile == 0) {
    meshGridProperties.set_threadgroups_per_grid(uint3(0, 0, 0));
    return;
  }
  payload.bladeCount = bladesInTile;

  for (uint i = 0; i < bladesInTile; i++) {
      float t = float(i) / float(bladesInTile - 1);
      float x = (t - 0.5) * settings.tileSize * 0.5;
      payload.bladePositions[i] = tileCenter + float3(x, 0.0, 0.0);
  }

  payload.tileID = objectID;

  meshGridProperties.set_threadgroups_per_grid(
    uint3(bladesInTile, 1, 1));
}

using GrassMesh = metal::mesh<VertexOut, void, 3, 1, topology::triangle>;

[[mesh]]
void mesh_grass(
  uint meshID [[threadgroup_position_in_grid]],
  uint threadID [[thread_index_in_threadgroup]],
  const object_data GrassPayload& payload [[payload]],
  GrassMesh outputMesh,
  constant GrassUniforms& uniforms [[buffer(GrassUniformsBuffer)]])
{
  float4 position;
  float4 color = { 0, 0.5, 0, 1 };
  switch (threadID) {
    case 0:
      position = { 0, 1, 0, 1 };
      position = float4( 0, randomNoise(float2(threadID, meshID)), 0, 1);
      color = { 0.5, 0.8, 0, 1};
      break;
    case 1:
      position = { -0.2, 0, 0, 1 };
      break;
    case 2:
      position = { 0.2, 0, 0, 1 };
      break;
  }

  position += float4(payload.bladePositions[meshID], 0);
  if (threadID < 3) {
    outputMesh.set_vertex(threadID, VertexOut {
      .position = uniforms.viewProjectionMatrix * position,
      .color = color
    });
    
    outputMesh.set_index(threadID, threadID);
  }
  if (threadID == 0) {
    outputMesh.set_primitive_count(1);
  }
}
