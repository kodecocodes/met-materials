#include <metal_stdlib>
using namespace metal;

// Create the Environment BRDF look-up texture

// http://holger.dammertz.org/stuff/notes_HammersleyOnHemisphere.html

float radicalInverse_VdC(uint bits) {
  bits = (bits << 16u) | (bits >> 16u);
  bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
  bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
  bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
  bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
  return float(bits) * 2.3283064365386963e-10; // / 0x100000000
}

float2 Hammersley(uint i, uint N) {
  return float2(float(i) / float(N), radicalInverse_VdC(i));
}

// http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf

float G_Smith(float roughness, float NoV, float NoL, bool ibl) {
  
  float k = ibl ? ((roughness) * (roughness)) / 2.0 : ((roughness + 1) * (roughness + 1)) / 8.0;
  float g1 = NoL / (NoL * (1.0 - k) + k);
  float g2 = NoV / (NoV * (1.0 - k) + k);
  return g1 * g2;
}

float3 ImportanceSampleGGX(float2 Xi, float Roughness, float3 N) {
  float a = Roughness * Roughness;
  float Phi = 2 * M_PI_F * Xi.x;
  float CosTheta = sqrt((1 - Xi.y) / (1 + (a * a - 1) * Xi.y));
  float SinTheta = sqrt(1 - CosTheta * CosTheta);
  
  float3 H;
  H.x = SinTheta * cos(Phi);
  H.y = SinTheta * sin(Phi);
  H.z = CosTheta;
  
  float3 UpVector = abs(N.z) < 0.999 ? float3(0, 0, 1) : float3(1, 0, 0);
  float3 TangentX = normalize(cross(UpVector, N));
  float3 TangentY = cross(N, TangentX);
  
  // Tangent to world space
  return TangentX * H.x + TangentY * H.y + N * H.z;
}

float2 IntegrateBRDF(float Roughness, float NoV) {
  float3 N = float3(0, 0, 1.0); // normal
  float3 V;
  V.x = sqrt(1.0 - NoV * NoV);  // sin
  V.y = 0;
  V.z = NoV;                    // cos
  
  float A = 0;
  float B = 0;
  
  const uint NumSamples = 1024;
  for (uint i = 0; i < NumSamples; i++) {
    float2 Xi = Hammersley( i, NumSamples );
    float3 H = ImportanceSampleGGX(Xi, Roughness, N );
    float3 L = 2 * dot( V, H ) * H - V;
    
    float NoL = saturate( L.z );
    float NoH = saturate( H.z );
    float VoH = saturate( dot( V, H ) );
    
    if( NoL > 0 ) {
      float G = G_Smith(Roughness, NoV, NoL, true);
      float G_Vis = G * VoH / (NoH * NoV); float Fc = pow( 1 - VoH, 5 );
      A += (1 - Fc) * G_Vis;
      B += Fc * G_Vis;
    }
  }
  return float2(A, B) / NumSamples;
}

kernel void integrateBRDF(texture2d<float, access::write> lut [[ texture(0) ]],
                          uint2 position [[ thread_position_in_grid ]]) {
  
  float width = lut.get_width();
  float height = lut.get_height();
  if (position.x >= width || position.y >= height) {
    return;
  }
  float Roughness = (position.x + 16.0) / width;
  float NoV = (position.y + 1.0) / height;
  
  // input (Roughness and cosTheta) - output (scale and bias to F0)
  float2 brdf = IntegrateBRDF(Roughness, NoV);
  float4 color(brdf, 0, 0);
  lut.write(color, position);
}
