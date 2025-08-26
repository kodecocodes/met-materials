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

#include "Common.h"

kernel void computeParticles(
  device Particle *particles [[buffer(0)]],
  constant ParticleAnimation &animation [[buffer(1)]],
  uint id [[thread_position_in_grid]])
{
  if (particles[id].age > particles[id].life) {
    particles[id].position = particles[id].startPosition;
    particles[id].velocity = particles[id].startVelocity;
    particles[id].age = 0;
    particles[id].scale = particles[id].startScale;
    particles[id].rotation = 0;
    return;
  }

  particles[id].velocity += animation.gravity;
  particles[id].velocity += animation.windForce;
  particles[id].velocity *= animation.damping;
  particles[id].position += particles[id].velocity * animation.deltaTime;

  particles[id].rotation += particles[id].angularVelocity;

  particles[id].age += 1.0;
  float age = particles[id].age / particles[id].life;

  if (age < 0.3) {
    float turbulence = sin(particles[id].age * 0.1 + particles[id].position.x * 0.5) * 0.2;
    particles[id].velocity.y += turbulence;
    particles[id].velocity.x += cos(particles[id].age * 0.15) * 0.01;
    particles[id].velocity.z += sin(particles[id].age * 0.12) * 0.01;
  }

  particles[id].scale =  mix(particles[id].startScale,
                             particles[id].endScale, age);
}

struct VertexOut {
  float4 position  [[position]];
  float2 uvs;
  float4 color;
};

struct Quad {
  float3 position [[attribute(Position)]];
  float2 uvs [[attribute(UV)]];
};

vertex VertexOut vertex_particle(
  Quad quad [[stage_in]],
  const device Particle *particles [[buffer(ParticlesBuffer)]],
  constant Uniforms *uniforms [[buffer(UniformsBuffer)]],
  constant float4x4 &modelMatrix [[buffer(2)]],
  uint instance [[instance_id]])
{
  float4 position = modelMatrix * float4(particles[instance].position, 1);
  float4 viewCenter = uniforms->viewMatrix * position;
  
  float size = particles[instance].size * particles[instance].scale * 0.01;
  viewCenter.xy += quad.position.xy * size;
  
  VertexOut out {
    .position = uniforms->projectionMatrix * viewCenter,
    .uvs = quad.uvs,
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
  
  float4 color = particleTexture.sample(default_sampler, in.uvs);
  if (color.a < 0.5) {
    discard_fragment();
  }
  color = float4(color.rgb, 0.5);
  color *= in.color;
  return color;
}
