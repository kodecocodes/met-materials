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

  // cull behind
  float3 cameraToTile = normalize(tileCenter - uniforms.cameraPosition);
  float3 cameraForward = normalize(uniforms.cameraForward);
  if (dot(cameraForward, cameraToTile) < -0.1) {
    meshGridProperties.set_threadgroups_per_grid(uint3(0, 0, 0));
    return;
  }
  
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

  auto simpleRandom = [](uint seed) -> float {
      seed = (seed ^ 61) ^ (seed >> 16);
      seed *= 9;
      seed = seed ^ (seed >> 4);
      seed *= 0x27d4eb2d;
      seed = seed ^ (seed >> 15);
      return float(seed) / 4294967296.0; // Convert to 0-1 range
  };

  for (uint i = 0; i < bladesInTile; i++) {
      // Create unique seed for each blade using tile ID and blade index
      uint seed = (objectID.x * 73856093) ^ (objectID.z * 19349663) ^ (i * 83492791);
      
      // Generate random offsets within the tile
      float offsetX = (simpleRandom(seed) - 0.5) * settings.tileSize;
      float offsetZ = (simpleRandom(seed + 1) - 0.5) * settings.tileSize;
      
      payload.bladePositions[i] = tileCenter + float3(offsetX, 0.0, offsetZ);
  }

  payload.tileID = objectID;
  meshGridProperties.set_threadgroups_per_grid(uint3(bladesInTile, 1, 1));
}

struct VertexOut {
  float4 position [[position]];
  float4 color;
};

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
