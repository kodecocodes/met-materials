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

constant float average = 100;
constant float attenuation = 0.1;
constant float cohesionWeight = 2.0;
constant float limit = 20;
constant float separationWeight = 1.0;
constant float neighbors = 8;
constant float alignmentWeight = 3.0;
constant float escapingWeight = 0.01;
constant float dampeningWeight = 1.0;

struct Boid {
  float2 position;
  float2 velocity;
};

float2 cohesion(uint index, device Boid* boids, uint particleCount) {
  Boid thisBoid = boids[index];
  float2 position = float2(0);
  for (uint i = 0; i < particleCount; i++) {
    Boid boid = boids[i];
    if (i != index) {
      position += boid.position;
    }
  }
  position /= (particleCount - 1);
  position = (position - thisBoid.position) / average;
  return position;
}

float2 separation(uint index, device Boid* boids, uint particleCount) {
  // 1
  Boid thisBoid = boids[index];
  float2 position = float2(0);
  // 2
  for (uint i = 0; i < particleCount; i++) {
    Boid boid = boids[i];
    if (i != index) {
      if (abs(distance(boid.position, thisBoid.position)) < limit) {
        position = position - (boid.position - thisBoid.position);
      }
    }
  }
  return position;
}

float2 alignment(uint index, device Boid* boids, uint particleCount) {
  // 1
  Boid thisBoid = boids[index];
  float2 velocity = float2(0);
  // 2
  for (uint i = 0; i < particleCount; i++) {
    Boid boid = boids[i];
    if (i != index) {
      velocity += boid.velocity;
    }
  }
  // 3
  velocity /= (particleCount - 1);
  velocity = (velocity - thisBoid.velocity) / neighbors;
  return velocity;
}

float2 escaping(Boid predator, Boid boid) {
  return -attenuation * (predator.position - boid.position) / average;
}

float2 dampening(Boid boid) {
  // 1
  float2 velocity = float2(0);
  // 2
  if (abs(boid.velocity.x) > limit) {
    velocity.x += boid.velocity.x / abs(boid.velocity.x) * attenuation;
  }
  if (abs(boid.velocity.y) > limit) {
    velocity.y = boid.velocity.y / abs(boid.velocity.y) * attenuation;
  }
  return velocity;
}


kernel void firstPass(texture2d<half, access::write> output [[ texture(0) ]],
                      uint2 id [[ thread_position_in_grid ]]) {
  output.write(half4(0.0), id);
}

kernel void secondPass(texture2d<half, access::write> output [[ texture(0) ]],
                       device Boid *boids [[ buffer(0) ]],
                       constant uint& particleCount [[ buffer(1) ]],
                       uint id [[ thread_position_in_grid ]]) {
  Boid predator = boids[0];
  Boid boid;
  if (id != 0) {
    boid = boids[id];
  }
  float2 position = boid.position;
  float2 velocity = boid.velocity;
  float2 cohesionVector = cohesion(id, boids, particleCount) * attenuation;
  float2 alignmentVector = alignment(id, boids, particleCount) * attenuation;
  float2 separationVector = separation(id, boids, particleCount) * attenuation;
  float2 escapingVector = escaping(predator, boid) * attenuation;
  float2 dampeningVector = dampening(boid) * attenuation;
  
  // velocity accumulation
  velocity += cohesionVector * cohesionWeight + separationVector * separationWeight + alignmentVector * alignmentWeight + escapingVector * escapingWeight + dampeningVector * dampeningWeight;
  
  if (position.x < 0 || position.x > output.get_width()) {
    velocity.x *= -1;
  }
  
  if (position.y < 0 || position.y > output.get_height()) {
    velocity.y *= -1;
  }
  
  position += velocity;
  boid.position = position;
  boid.velocity = velocity;
  boids[id] = boid;
  
  if (predator.position.x < 0 || predator.position.x > output.get_width()) {
    predator.velocity.x *= -1;
  }
  if (predator.position.y < 0 || predator.position.y > output.get_height()) {
    predator.velocity.y *= -1;
  }
  predator.position += predator.velocity / 2.0;
  boids[0] = predator;
  
  uint2 location = uint2(position);
  half4 color = half4(1.0);
  if (id == 0) {
    color = half4(1.0, 0.0, 0.0, 1.0);
    location = uint2(boids[0].position);
  }
  output.write(color, location);
  output.write(color, location + uint2( 1, 0));
  output.write(color, location + uint2( 0, 1));
  output.write(color, location - uint2( 1, 0));
  output.write(color, location - uint2( 0, 1));
  output.write(color, location + uint2(-1, 1));
  output.write(color, location - uint2(-1, 1));
  output.write(color, location + uint2( 1,-1));
  output.write(color, location - uint2( 1,-1));
}
