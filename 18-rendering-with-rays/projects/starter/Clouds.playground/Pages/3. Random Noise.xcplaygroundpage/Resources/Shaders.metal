
#include <metal_stdlib>
using namespace metal;

kernel void compute(texture2d<float, access::write> output [[texture(0)]],
                    constant float &time [[buffer(0)]],
                    uint2 gid [[thread_position_in_grid]]) {
  int width = output.get_width();
  int height = output.get_height();
  float2 resolution = float2(width, height);
  float2 uv = float2(gid) / resolution;
  output.write(float4(0.0), gid);
}
