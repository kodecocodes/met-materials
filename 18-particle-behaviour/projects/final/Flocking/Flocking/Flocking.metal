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
#import "Helper.h"

float2 checkSpeed(float2 vector, float minSpeed, float maxSpeed) {
  float speed = length(vector);
  if (speed < minSpeed) {
    return vector / speed * minSpeed;
  }
  if (speed > maxSpeed) {
    return vector / speed * maxSpeed;
  }
  return vector;
}

float2 cohesion(Params params, uint index, device Boid* boids) {
  Boid thisBoid = boids[index];
  float neighborsCount = 0;
  float2 cohesion = 0.0;
  for (uint i = 1; i < params.particleCount; i++) {
    Boid boid = boids[i];
    float d = distance(thisBoid.position, boid.position);
    if (d < params.neighborRadius && i != index) {
      cohesion += boid.position;
      neighborsCount++;
    }
  }
  if (neighborsCount > 0) {
    cohesion /= neighborsCount;
    cohesion -= thisBoid.position;
    cohesion *= params.cohesionStrength;
  }
  return cohesion;
}

float2 separation(Params params, uint index, device Boid* boids)
{
  Boid thisBoid = boids[index];
  float2 separation = float2(0);
  for (uint i = 1; i < params.particleCount; i++) {
    Boid boid = boids[i];
    if (i != index) {
      if (abs(distance(boid.position, thisBoid.position))
            < params.separationRadius) {
        separation -= (boid.position - thisBoid.position);
      }
    }
  }
  separation *= params.separationStrength;
  return separation;
}

float2 alignment(Params params, uint index, device Boid* boids)
{
  Boid thisBoid = boids[index];
  float neighborsCount = 0;
  float2 velocity = 0.0;
  for (uint i = 1; i < params.particleCount; i++) {
    Boid boid = boids[i];
    float d = distance(thisBoid.position, boid.position);
    if (d < params.neighborRadius && i != index) {
      velocity += boid.velocity;
      neighborsCount++;
    }
  }
  if (neighborsCount > 0) {
    velocity = velocity / neighborsCount;
    velocity = (velocity - thisBoid.velocity);
    velocity *= params.alignmentStrength;
  }
  return velocity;
}

float2 updatePredator(Params params, device Boid* boids)
{
  float2 preyPosition = boids[0].position;
  for (uint i = 1; i < params.particleCount; i++) {
    float d = distance(preyPosition, boids[i].position);
    if  (d < params.predatorSeek) {
      preyPosition = boids[i].position;
      break;
    }
  }
  return preyPosition - boids[0].position;
}

float2 escaping(Params params, Boid predator, Boid boid) {
  float2 velocity = boid.velocity;
  float d = distance(predator.position, boid.position);
  if (d < params.predatorRadius) {
    velocity = boid.position - predator.position;
    velocity *= params.predatorStrength;
  }
  return velocity;
}

kernel void flocking(
  texture2d<half, access::write> output [[texture(0)]],
  device Boid *boids [[buffer(0)]],
  constant Params &params [[buffer(1)]],
  uint id [[thread_position_in_grid]])
{
  Boid boid = boids[id];
  float2 position = boid.position;

  float2 velocity = boid.velocity;

  if (id == 0) {
    float2 predatorVector = updatePredator(params, boids);
    velocity += predatorVector;
    velocity =
      checkSpeed(velocity, params.minSpeed, params.predatorSpeed);
  } else {
    float2 cohesionVector = cohesion(params, id, boids);
    float2 separationVector = separation(params, id, boids);
    float2 alignmentVector = alignment(params, id, boids);
    float2 escapingVector = escaping(params, boids[0], boid);

    // velocity accumulation
    velocity += cohesionVector + separationVector
     + alignmentVector + escapingVector;

    velocity =
    checkSpeed(velocity, params.minSpeed, params.maxSpeed);
  }
  position += velocity;

  float2 viewSize = float2(output.get_width(), output.get_height());
  if (id == 0) {
    boid = bounceBoid(position, velocity, viewSize);
  } else {
    boid.position = wrapPosition(position, viewSize);
    boid.velocity = velocity;
  }

  boids[id] = boid;

  half4 color = half4(1.0);
  if (id == 0) {
    color = half4(1, 0, 0, 1);
  }
  uint2 location = uint2(position);
  int size = 4;
  for (int x = -size; x <= size; x++) {
    for (int y = -size; y <= size; y++) {
      output.write(color, location + uint2(x, y));
    }
  }
}

kernel void clearScreen(
  texture2d<half, access::write> output [[texture(0)]],
  uint2 id [[thread_position_in_grid]])
{
  output.write(half4(0.0, 0.0, 0.0, 1.0), id);
}
