
#include <metal_stdlib>
using namespace metal;

kernel void compute(texture2d<float, access::write> output [[texture(0)]],
                    uint2 gid [[thread_position_in_grid]]) {
  int width = output.get_width();
  int height = output.get_height();
  float2 uv = float2(gid) / float2(width, height);
  uv = uv * 2.0 - 1.0;
  float4 color = float4(0.41, 0.61, 0.86, 1.0);
  
  // SDF
  
  output.write(color, gid);
}
