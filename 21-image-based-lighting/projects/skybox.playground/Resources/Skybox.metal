#include <metal_stdlib>
using namespace metal;

struct VertexIn {
  float4 position [[attribute(0)]];
};

struct VertexOut {
  float4 position [[position]];
  float3 uvw;
};

vertex VertexOut vertex_skybox(const VertexIn in [[ stage_in ]],
                               constant float4x4 &vp [[ buffer(1) ]]){

  VertexOut out;
  out.position = (vp * in.position).xyww;
  out.uvw = in.position.xyz;
  return out;
}

fragment half4 fragment_skybox(VertexOut in [[ stage_in ]],
             texturecube<half> cubeTexture [[ texture(0) ]]){
  constexpr sampler default_sampler;
  half4 color = cubeTexture.sample(default_sampler, in.uvw);
  return color;
}
