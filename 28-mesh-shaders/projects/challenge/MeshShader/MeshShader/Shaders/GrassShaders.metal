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

float simpleHash(float2 coords) {
  float h = dot(coords, float2(127.1, 311.7));
  return fract(sin(h) * 43758.5453);
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

  float3 cameraToTile = normalize(tileCenter - uniforms.cameraPosition);
  float3 cameraForward = normalize(uniforms.cameraForward);
  if (dot(cameraForward, cameraToTile) < -0.4) {
    meshGridProperties.set_threadgroups_per_grid(0);
    return;
  }

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
    meshGridProperties.set_threadgroups_per_grid(0);
    return;
  }

  payload.bladeCount = bladesInTile;

  for (uint i = 0; i < bladesInTile; i++) {
    float randX = simpleHash(float2(objectID.xz) + float2(i, 0));
    float randY = simpleHash(float2(objectID.xz) + float2(0, i));
    float offsetX = (randX - 0.5) * settings.tileSize;
    float offsetZ = (randY - 0.5) * settings.tileSize;
    float3 offset = float3(offsetX, 0, offsetZ);
    payload.bladePositions[i] = tileCenter + offset;
  }
  payload.tileID = objectID;

  meshGridProperties.set_threadgroups_per_grid(
    uint3(bladesInTile, 1, 1));
}

float randomRange(float2 coords, float offset, float minValue, float maxValue) {
  return simpleHash(coords + offset) * (maxValue - minValue) + minValue;
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
  float2 seed = payload.bladePositions[meshID].xz;
  float heightVariation = randomRange(seed, 0.0, 0.2, 1.5);
  float colorVariation = randomRange(seed, 300.0, 1, 1.2);
  
  float4 colorBase = { 0.1, 0.1 * colorVariation , 0, 1 };
  float4 colorTop = { 0.3 * colorVariation , 0.8 * colorVariation , 0, 1 };
  float4 color;
  switch (threadID) {
    case 0:    // top vertex
      position = { 0, 1 * heightVariation, 0, 1 };
      color = colorTop;
      break;
    case 1:    // bottom left vertex
      position = { -0.1, 0, 0, 1 };
      color = colorBase;
      break;
    case 2:    // bottom right vertex
      position = { 0.1, 0, 0, 1 };
      color = colorBase;
      break;
  }
 
  // rotate for billboarding
  float3 worldPosition = payload.bladePositions[meshID];
  float3 cameraDirection = normalize(uniforms.cameraPosition - worldPosition);
  float3 up = float3(0, 1, 0);
  float3 right = normalize(cross(up, cameraDirection));
  float billboard = atan2(right.z, right.x);
  float newX = position.x * cos(billboard) - position.z * sin(billboard);
  float newZ = position.x * sin(billboard) + position.z * cos(billboard);
  position.x = newX;
  position.z = newZ;
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
