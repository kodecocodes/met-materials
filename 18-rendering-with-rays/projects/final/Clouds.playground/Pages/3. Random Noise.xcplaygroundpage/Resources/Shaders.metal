
#include <metal_stdlib>
using namespace metal;

float randomNoise(float2 p) {
  return fract(6791.0 * sin(47.0 * p.x + 9973.0 * p.y));
}

float smoothNoise(float2 p) {
  float2 north = float2(p.x, p.y + 1.0);
  float2 east = float2(p.x + 1.0, p.y);
  float2 south = float2(p.x, p.y - 1.0);
  float2 west = float2(p.x - 1.0, p.y);
  float2 center = float2(p.x, p.y);
  float sum = 0.0;
  sum += randomNoise(north) / 8.0;
  sum += randomNoise(east) / 8.0;
  sum += randomNoise(south) / 8.0;
  sum += randomNoise(west) / 8.0;
  sum += randomNoise(center) / 2.0;
  return sum;
}

float interpolatedNoise(float2 p) {
  float q11 = smoothNoise(float2(floor(p.x), floor(p.y)));
  float q12 = smoothNoise(float2(floor(p.x), ceil(p.y)));
  float q21 = smoothNoise(float2(ceil(p.x), floor(p.y)));
  float q22 = smoothNoise(float2(ceil(p.x), ceil(p.y)));
  float2 ss = smoothstep(0.0, 1.0, fract(p));
  float r1 = mix(q11, q21, ss.x);
  float r2 = mix(q12, q22, ss.x);
  return mix (r1, r2, ss.y);
}

float fbm(float2 uv, float steps) {
  float sum = 0;
  float amplitude = 0.8;
  for(int i = 0; i < steps; ++i) {
    sum += interpolatedNoise(uv) * amplitude;
    uv += uv * 1.2;
    amplitude *= 0.4;
  }
  return sum;
}

kernel void compute(texture2d<float, access::write> output [[texture(0)]],
                    constant float &time [[buffer(0)]],
                    uint2 gid [[thread_position_in_grid]]) {
  int width = output.get_width();
  int height = output.get_height();
  float2 resolution = float2(width, height);
  float2 uv = float2(gid) / resolution;
  float tiles = 4.0;
  uv *= tiles;
  float noise = fbm(uv, tiles);
  output.write(float4(float3(noise), 1.0), gid);
}
