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
#import "ShaderDefs.h"
#import "Lighting.h"

fragment float4 fragment_terrain(
  FragmentIn in [[stage_in]],
  constant Params &params [[buffer(ParamsBuffer)]],
  constant Light *lights [[buffer(LightBuffer)]],
  depth2d<float> shadowTexture [[texture(ShadowTexture)]],
  texture2d<float> baseColor [[texture(BaseColor)]],
  texture2d<float> underwaterTexture [[texture(MiscTexture)]])
{
  constexpr sampler default_sampler(filter::linear, address::repeat);
  float4 color;
  float4 grass = baseColor.sample(default_sampler, in.uv * params.tiling);
  color = grass;

  // uncomment this for pebbles
  float4 underwater = underwaterTexture.sample(
    default_sampler,
    in.uv * params.tiling);
  float lower = -1.3;
  float upper = 0.2;
  float y = in.worldPosition.y;
  float waterHeight = (upper - y) / (upper - lower);
  in.worldPosition.y < lower ?
  (color = underwater) :
  (in.worldPosition.y > upper ?
   (color = grass) :
   (color = mix(grass, underwater, waterHeight))
   );

  float3 normal = normalize(in.worldNormal);
  Light light = lights[0];
  float3 lightDirection = normalize(light.position);
  float diffuseIntensity = saturate(dot(lightDirection, normal));
  float maxIntensity = 1;
  float minIntensity = 0.2;
  diffuseIntensity = diffuseIntensity * (maxIntensity - minIntensity) + minIntensity;
  color *= diffuseIntensity;
  color *= calculateShadow(in.shadowPosition, shadowTexture);
  return color;
}


