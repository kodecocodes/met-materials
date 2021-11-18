/**
 * Copyright (c) 2019 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#ifndef Common_h
#define Common_h

#import <simd/simd.h>

typedef matrix_float4x4 float4x4;
typedef matrix_float3x3 float3x3;
typedef vector_float2 float2;
typedef vector_float3 float3;
typedef vector_float4 float4;

typedef struct {
  float4x4 modelMatrix;
  float4x4 viewMatrix;
  float4x4 projectionMatrix;
  float3x3 normalMatrix;
  float4x4 shadowMatrix;
} Uniforms;

typedef struct {
  uint lightCount;
  float3 cameraPosition;
} FragmentUniforms;

typedef enum {
  unused = 0,
  Sunlight = 1,
  Spotlight = 2,
  Pointlight = 3,
  Ambientlight = 4
} LightType;

typedef struct {
  float3 position;
  float3 color;
  float3 specularColor;
  float intensity;
  float3 attenuation;
  LightType type;
  float coneAngle;
  float3 coneDirection;
  float coneAttenuation;
} Light;

typedef struct {
  float3 emissionColor;
  float3 baseColor;
  float3 specularColor;
  float shininess;
} Material;

#endif /* Common_h */
