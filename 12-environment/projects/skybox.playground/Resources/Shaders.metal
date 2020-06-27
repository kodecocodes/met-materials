#include <metal_stdlib>
using namespace metal;

struct VertexOut {
  float4 position [[ position ]];
  float4 color;
  float3 normal;
  float2 uv;
};


vertex VertexOut vertex_terrain(const device packed_float3 *vertices [[ buffer(0) ]],
                              constant float4x4 &mvp_matrix [[ buffer(1) ]],
                              constant packed_float2 *uvs [[ buffer(3) ]],
                              uint vertex_id [[ vertex_id ]]) {
  VertexOut out;
  out.position = mvp_matrix * float4(vertices[vertex_id], 1);
  out.uv = uvs[vertex_id];
  return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant float2 &tiling [[buffer(1)]],
                              texture2d<float> texture [[texture(0)]]) {
  constexpr sampler s(filter::linear,
                     address::repeat, mip_filter::linear,
                     mag_filter::linear, min_filter::linear);
  float4 color = texture.sample(s, in.uv * tiling);
  return color;
}
