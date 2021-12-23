/// Copyright (c) 2021 Razeware LLC
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

#import "Common.h"

float3 phongLighting(
  float3 worldNormal,
  float3 worldPosition,
  constant Params &params,
  constant Light *lights,
  Material material) {
    float3 baseColor = material.baseColor;
    float3 diffuseColor = 0;
    float3 ambientColor = 0;
    float3 specularColor = 0;
    float materialShininess = material.shininess;
    float3 materialSpecularColor = material.specularColor;
    float3 normalDirection = normalize(worldNormal);
    for (uint i = 0; i < params.lightCount; i++) {
      Light light = lights[i];
      if (light.type == Sunlight) {
        float3 lightDirection = normalize(-light.position);
        float diffuseIntensity =
          saturate(-dot(lightDirection, normalDirection));
        diffuseColor += light.color * baseColor * diffuseIntensity;
        if (diffuseIntensity > 0) {
          float3 reflection =
              reflect(lightDirection, normalDirection);
          float3 viewDirection =
              normalize(params.cameraPosition - worldPosition);
          float specularIntensity =
              pow(saturate(dot(reflection, viewDirection)),
                  materialShininess);
          specularColor +=
              light.specularColor * materialSpecularColor
                * specularIntensity;
        }
      }
      else if (light.type == Ambientlight) {
        ambientColor += baseColor * light.color;
      }
      else if (light.type == Pointlight) {
        float d = distance(light.position, worldPosition);
        float3 lightDirection = normalize(light.position
                                          - worldPosition);
        float attenuation = 1.0 / (light.attenuation.x +
            light.attenuation.y * d + light.attenuation.z * d * d);

        float diffuseIntensity =
            saturate(dot(lightDirection, normalDirection));
        float3 color = light.color * baseColor * diffuseIntensity;
        color *= attenuation;
        diffuseColor += color;
      }
      else if (light.type == Spotlight) {
        float d = distance(light.position, worldPosition);
        float3 lightDirection = normalize(light.position
                                          - worldPosition);
        float3 coneDirection = normalize(light.coneDirection);
        float spotResult = dot(lightDirection, -coneDirection);
        if (spotResult > cos(light.coneAngle)) {
          float attenuation = 1.0 / (light.attenuation.x +
              light.attenuation.y * d + light.attenuation.z * d * d);
          attenuation *= pow(spotResult, light.coneAttenuation);
          float diffuseIntensity =
                   saturate(dot(lightDirection, normalDirection));
          float3 color = light.color * baseColor * diffuseIntensity;
          color *= attenuation;
          diffuseColor += color;
        }
      }
    }
    float3 color = diffuseColor + ambientColor + specularColor;
    return color;
}
