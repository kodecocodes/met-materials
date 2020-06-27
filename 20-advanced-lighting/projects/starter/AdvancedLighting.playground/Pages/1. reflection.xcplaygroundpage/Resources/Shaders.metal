
#include <metal_stdlib>
using namespace metal;

struct Ray {
  float3 origin;
  float3 dir;
};

struct Light {
  float3 pos;
};

struct Camera {
  float3 pos;
  Ray ray;
  float rayDivergence;
};

struct Sphere {
  float3 center;
  float radius;
};

struct Plane {
  float yCoord;
};

float unionOp(float d0, float d1) {
  return min(d0, d1);
}

float distToSphere(Ray r, Sphere s) {
  float d = distance(r.origin, s.center);
  return d - s.radius;
}

float distToPlane(Ray r, Plane p) {
  return r.origin.y - p.yCoord;
}

float2 distToScene(Ray r) {
  Plane p = Plane{0.0};
  float dtp = distToPlane(r, p);
  Sphere s = Sphere{float3(0.0, 6.0, 0.0), 6.0};
  float dts = distToSphere(r, s);
  float dist = unionOp(dts, dtp);
  return dist;
}

float3 getNormal(Ray ray) {
  float2 eps = float2(0.001, 0.0);
  float3 n = float3(distToScene(Ray{ray.origin + eps.xyy, ray.dir}).x -
                    distToScene(Ray{ray.origin - eps.xyy, ray.dir}).x,
                    distToScene(Ray{ray.origin + eps.yxy, ray.dir}).x -
                    distToScene(Ray{ray.origin - eps.yxy, ray.dir}).x,
                    distToScene(Ray{ray.origin + eps.yyx, ray.dir}).x -
                    distToScene(Ray{ray.origin - eps.yyx, ray.dir}).x);
  return normalize(n);
}

float ao(float3 pos, float3 n) {
  float eps = 0.01;
  pos += n * eps * 2.0;
  float occlusion = 0.0;
  for (float i = 1.0; i < 10.0; i++) {
    float dist = distToScene(Ray{pos, float3(0)}).x;
    float coneWidth = 2.0 * eps;
    float occlusionAmount = max(coneWidth - dist, 0.0);
    float occlusionFactor = occlusionAmount / coneWidth;
    occlusionFactor *= 1.0 - (i / 10.0);
    occlusion = max(occlusion, occlusionFactor);
    eps *= 2.0;
    pos += n * eps;
  }
  return max(0.0, 1.0 - occlusion);
}

Camera setupCam(float3 pos, float3 target, float fov, float2 uv, float width) {
  uv *= fov;
  float3 cw = normalize (target - pos);
  float3 cp = float3 (0.0, 1.0, 0.0);
  float3 cu = normalize(cross(cw, cp));
  float3 cv = normalize(cross(cu, cw));
  float3 dir = normalize (uv.x * cu + uv.y * cv + 0.5 * cw);
  Ray ray{pos, dir};
  Camera cam{pos, ray, fov / width};
  return cam;
}

kernel void compute(texture2d<float, access::write> output [[ texture(0) ]],
                    uint2 gid [[ thread_position_in_grid ]]) {
  int width = output.get_width();
  int height = output.get_height();
  float2 uv = float2(gid) / float2(width, height);
  uv = uv * 2.0 - 1.0;
  uv.y *= -1.0;
  float3 camPos = float3(15.0, 7.0, 0.0);
  Camera cam = setupCam(camPos, float3(0.0), 1.25, uv, float(width));
  float3 col = float3(0.9);
  float eps = 0.01;
  bool hit = false;
  for (int i = 0; i < 300; i++) {
    float2 dist = distToScene(cam.ray);
    if (dist.x < eps) {
      hit = true;
    }
    cam.ray.origin += cam.ray.dir * dist.x;
    eps += cam.rayDivergence * dist.x;
  }
  if (!hit) {
    col = mix(float3(.8, .8, .4), float3(.4, .4, 1.), cam.ray.dir.y);
  } else {
    float3 n = getNormal(cam.ray);
    float o = ao(cam.ray.origin, n);
    col = col * o;
  }
  output.write(float4(col, 1.0), gid);
}
