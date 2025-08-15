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

/*
// Simple payload structure - just grass blade positions
struct GrassPayload {
  float3 bladePositions[9];  // Max 64 blades per tile
  uint bladeCount;
};
*/
// Uniforms passed to the object shader
struct ObjectUniforms {
  float4x4 viewMatrix;
  float4 cameraPosition;
  float maxDistance;          // Distance where grass density becomes zero
  uint maxBladesPerTile;     // Maximum blades per tile (when very close)
  float gridSize;             // width x height (square)
  float tileSize;            // Size of each terrain tile
};

#include <metal_stdlib>
using namespace metal;

[[object]]
void grassObjectShader(uint3 objectID [[threadgroup_position_in_grid]],
                       object_data GrassPayload& payload [[payload]],
                       mesh_grid_properties meshGridProperties,
                       constant ObjectUniforms& uniforms [[buffer(0)]])
{

  // Calculate center world position of this tile
  float3 tileCenter = float3(objectID.x * uniforms.tileSize,
                             0.0,
                             objectID.z * uniforms.tileSize);
  
  
  // Offset by half the grid to center around origin
  float halfGrid = (uniforms.gridSize - 1.0) * 0.5;
  
  tileCenter = float3(
      (float(objectID.x) - halfGrid) * uniforms.tileSize,  // -1, 0, +1 for 3x3
      0.0,
      (float(objectID.z) - halfGrid) * uniforms.tileSize   // -1, 0, +1 for 3x3
  );

  // Calculate distance from camera to this tile
//  float distanceToCamera = length(uniforms.cameraPosition - tileCenter);
  
//  // Create discrete LOD levels to prevent flickering
//  uint bladesInTile;
//  if (distanceToCamera < uniforms.maxDistance * 0.3) {
//    bladesInTile = uniforms.maxBladesPerTile;        // Close: full density
//  } else if (distanceToCamera < uniforms.maxDistance * 0.6) {
//    bladesInTile = uniforms.maxBladesPerTile / 2;    // Medium: half density
//  } else if (distanceToCamera < uniforms.maxDistance) {
//    bladesInTile = uniforms.maxBladesPerTile / 4;    // Far: quarter density
//  } else {
//    bladesInTile = 0;                                // Very far: no grass
//  }
  
  uint bladesInTile = uniforms.maxBladesPerTile;
  
  // Clamp to our payload limit
  bladesInTile = min(bladesInTile, 64u);
  
  if (bladesInTile == 0) {
    // No grass for this tile - don't spawn any mesh threadgroups
    meshGridProperties.set_threadgroups_per_grid(uint3(0, 0, 0));
    return;
  }
  
  // Generate grid positions within the tile for each grass blade
  payload.bladeCount = bladesInTile;
  
  // Calculate grid dimensions - make a square grid as close as possible
  uint bladesPerSide = uint(ceil(sqrt(float(bladesInTile))));
  float spacing = uniforms.tileSize / float(bladesPerSide);
  float halfTile = uniforms.tileSize * 0.5;
  
  for (uint i = 0; i < bladesInTile; i++) {
    // Calculate grid position
    uint gridX = i % bladesPerSide;
    uint gridZ = i / bladesPerSide;
    
    // Convert grid position to world offset from tile center
    float offsetX = (float(gridX) * spacing) - halfTile + (spacing * 0.5);
    float offsetZ = (float(gridZ) * spacing) - halfTile + (spacing * 0.5);
    
    payload.bladePositions[i] = tileCenter + float3(offsetX, 0.0, offsetZ);
  }
  
  payload.tileID = objectID;
  
//  // Simple linear distribution across the tile
//  for (uint i = 0; i < bladesInTile; i++) {
//      float t = float(i) / float(bladesInTile - 1);  // 0.0 to 1.0
//      float offsetX = (t * uniforms.tileSize) - (uniforms.tileSize * 0.5);
//      payload.bladePositions[i] = tileCenter + float3(offsetX, 0.0, 0.0);
//  }
  
  // Spawn one mesh threadgroup per grass blade
  meshGridProperties.set_threadgroups_per_grid(uint3(bladesInTile, 1, 1));
  
  
//  // In object shader:
//  payload.bladeCount = 3;  // Always exactly 3 blades
//  payload.bladePositions[0] = float3(0, 0, 0);
//  payload.bladePositions[1] = float3(1, 0, 0);
//  payload.bladePositions[2] = float3(2, 0, 0);
//  
//  meshGridProperties.set_threadgroups_per_grid(uint3(3, 1, 1));
}

// Vertex output structure
struct GrassVertex {
  float4 position [[position]];
  float3 worldPosition;
  float3 normal;
  float2 texCoord;
  float4 color;
};

// Uniforms for the mesh shader
struct MeshUniforms {
  float4x4 viewProjectionMatrix;
  float4 cameraPosition;     // for billboarding
  float bladeHeight;         // Height of grass blades
  float bladeWidth;          // Width of grass blades
};



// Use the tile ID to generate a unique color per tile
//float4 getTileColor(uint3 tileID) {
//    // Simple hash-based color generation
//    float r = float((tileID.x * 73 + tileID.z * 149) % 255) / 255.0;
//    float g = float((tileID.x * 97 + tileID.z * 127) % 255) / 255.0;
//    float b = float((tileID.x * 83 + tileID.z * 137) % 255) / 255.0;
//    
//    return float4(r, g, b, 1.0);
//}

//float4 getTileColor(uint3 tileID) {
//    float n = fract(sin(dot(float2(tileID.x, tileID.z),
//                            float2(12.9898, 78.233))) * 43758.5453);
//    // Offset the base random value for r/g/b channels
//    float r = fract(n + 0.33);
//    float g = fract(n + 0.66);
//    float b = n;
//    return float4(r, g, b, 1.0);
//}

//float4 getTileColor(uint3 tileID) {
//    float r = fmod(tileID.x, 3.0) / 2.0;
//    float g = fmod(tileID.z, 3.0) / 2.0;
//    float b = fmod(tileID.x + tileID.z, 3.0) / 2.0;
//    return float4(r, g, b, 1.0);
//}

float4 getTileColor(uint3 tileID) {
    float r = fract(tileID.x * 0.21);
    float g = fract(tileID.z * 0.37);
    float b = fract((tileID.x + tileID.z) * 0.13);
    return float4(r, g, b, 1.0);
}

// payload structure type
// the primitive data type. void means no per primitive data
// max number of vertices
// max number of primitives
// primitive type
using GrassMesh = metal::mesh<GrassVertex, void, 3, 1, topology::triangle>;

[[mesh]]
void grassMeshShader(uint3 meshID [[threadgroup_position_in_grid]],
                     uint threadID [[thread_index_in_threadgroup]],
                     const object_data GrassPayload& payload [[payload]],
                     GrassMesh outputMesh,
                     constant MeshUniforms& uniforms [[buffer(0)]])
{
  // Each mesh threadgroup generates one grass blade
  uint bladeIndex = meshID.x;
  
  // Safety check
  if (bladeIndex >= payload.bladeCount) {
    return;
  }

  // Get the world position for this grass blade
  float3 bladeBase = payload.bladePositions[bladeIndex];

//  // Simple wind animation using sine wave
//  float windOffset = sin(uniforms.time * 2.0 + bladeBase.x * 0.1 + bladeBase.z * 0.1) * 0.3;
//  windOffset = 0;
//  // Create a simple quad for the grass blade (2 triangles, 4 vertices)
//  // We'll make it face the camera for simplicity (billboard style)
  
  // Calculate direction from blade to camera for proper billboarding
  float3 toCameraDir = normalize(uniforms.cameraPosition.xyz - bladeBase);
  float3 rightDir = normalize(cross(toCameraDir, float3(0.0, 1.0, 0.0)));
  
  
  float halfWidth = uniforms.bladeWidth * 0.5;
  float height = uniforms.bladeHeight;
  
  // Only first 3 threads encode vertices
    if (threadID < 3) {
        GrassVertex grassVertex;
        
        switch (threadID) {
            case 0: // Bottom left
            grassVertex.worldPosition = bladeBase + rightDir * (-halfWidth);
            grassVertex.texCoord = float2(0.0, 1.0);
                break;
            case 1: // Bottom right
            grassVertex.worldPosition = bladeBase + rightDir * halfWidth;
            grassVertex.texCoord = float2(1.0, 1.0);
                break;
            case 2: // Top center - no wind offset
            grassVertex.worldPosition = bladeBase + float3(0.0, height, 0.0);
            grassVertex.texCoord = float2(0.5, 0.0);
                break;
        }
    
    // Transform to clip space
    grassVertex.position = uniforms.viewProjectionMatrix * float4(grassVertex.worldPosition, 1.0);
    
    // Simple normal pointing up
    grassVertex.normal = float3(0.0, 1.0, 0.0);
    
    // Color gradient from brown at base to green at tip
    float greenAmount = 1.0 - grassVertex.texCoord.y; // More green at top
    grassVertex.color = float4(0.2 + greenAmount * 0.3, 0.4 + greenAmount * 0.4, 0.1, 1.0);
    
      grassVertex.color = getTileColor(payload.tileID);
      
    outputMesh.set_vertex(threadID, grassVertex);
  }
  
  // First 3 threads encode indices
    if (threadID < 3) {
        outputMesh.set_index(threadID, threadID); // Simple: 0, 1, 2
    }
    
    // Only one thread sets the primitive count
    if (threadID == 0) {
        outputMesh.set_primitive_count(1); // 1 triangle per grass blade
    }
}

fragment float4 grassFragmentShader(GrassVertex in [[stage_in]])
{
  return in.color;
}
