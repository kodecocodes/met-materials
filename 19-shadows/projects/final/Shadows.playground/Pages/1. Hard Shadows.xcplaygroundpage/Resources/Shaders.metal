
#include <metal_stdlib>
using namespace metal;

struct Rectangle {
  float2 center;
  float2 size;
};

float distanceToRectangle(float2 point, Rectangle rectangle) {
  float2 distances = abs(point - rectangle.center) - rectangle.size / 2;
  return
    all(sign(distances) > 0)
    ? length(distances)
    : max(distances.x, distances.y);
}

float differenceOperator(float d0, float d1) {
  return max(d0, -d1);
}

float distanceToScene(float2 point) {
  Rectangle r1 = Rectangle{float2(0.0), float2(0.3)};
  float d2r1 = distanceToRectangle(point, r1);
  Rectangle r2 = Rectangle{float2(0.05), float2(0.04)};
  float2 mod = point - 0.1 * floor(point / 0.1);
  float d2r2 = distanceToRectangle(mod, r2);
  float diff = differenceOperator(d2r1, d2r2);
  return diff;
}

float getShadow(float2 point, float2 lightPos) {
  float2 lightDir = normalize(lightPos - point);
  float shadowDistance = 0.75;
  float distAlongRay = 0.0;
  for (float i = 0; i < 80; i++) {
    float2 currentPoint = point + lightDir * distAlongRay;
    float d2scene = distanceToScene(currentPoint);
    if (d2scene <= 0.001) { return 0.0; }
    distAlongRay += d2scene;
    if (distAlongRay > shadowDistance) { break; }
  }
  return 1.0;
}

kernel void compute(texture2d<float, access::write> output [[texture(0)]],
                    constant float &time [[buffer(0)]],
                    uint2 gid [[thread_position_in_grid]]) {
  int width = output.get_width();
  int height = output.get_height();
  float2 uv = float2(gid) / float2(width, height);
  uv = uv * 2.0 - 1.0;
  float d2scene = distanceToScene(uv);
  bool inside = d2scene < 0.0;
  float4 color = inside ? float4(0.8,0.5,0.5,1.0) : float4(0.9,0.9,0.8,1.0);
  float2 lightPos = 2.8 * float2(sin(time), cos(time));
  float dist2light = length(lightPos - uv);
  color *= max(0.3, 2.0 - dist2light);
  float shadow = getShadow(uv, lightPos);
  color *= 2;
  color *= shadow * .5 + .5;
  output.write(color, gid);
}
