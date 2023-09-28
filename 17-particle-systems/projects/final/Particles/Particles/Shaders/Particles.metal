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

kernel void computeParticles(
  device Particle *particles [[buffer(0)]],
  uint id [[thread_position_in_grid]])
{
  float xVelocity = particles[id].speed
                      * cos(particles[id].direction);
  float yVelocity = particles[id].speed
                      * sin(particles[id].direction);
  particles[id].position.x += xVelocity;
  particles[id].position.y += yVelocity;
  particles[id].age += 1.0;
  float age = particles[id].age / particles[id].life;
  particles[id].scale =  mix(particles[id].startScale,
                             particles[id].endScale, age);
  if (particles[id].age > particles[id].life) {
    particles[id].position = particles[id].startPosition;
    particles[id].age = 0;
    particles[id].scale = particles[id].startScale;
  }
}

struct VertexOut {
  float4 position  [[position]];
  float  point_size [[point_size]];
  float4 color;
};

vertex VertexOut vertex_particle(
  constant float2 &size [[buffer(0)]],
  const device Particle *particles [[buffer(1)]],
  constant float2 &emitterPosition [[buffer(2)]],
  uint instance [[instance_id]])
{
  float2 position = particles[instance].position
    + emitterPosition;
  VertexOut out {
    .position =
      float4(position.xy / size * 2.0 - 1.0, 0, 1),
    .point_size = particles[instance].size
      * particles[instance].scale,
    .color = particles[instance].color
  };
  return out;
}

fragment float4 fragment_particle(
  VertexOut in [[stage_in]],
  texture2d<float> particleTexture [[texture(0)]],
  float2 point [[point_coord]])
{
  constexpr sampler default_sampler;
  float4 color = particleTexture.sample(default_sampler, point);
  if (color.a < 0.5) {
    discard_fragment();
  }
  color = float4(color.xyz, 0.5);
  color *= in.color;
  return color;
}
