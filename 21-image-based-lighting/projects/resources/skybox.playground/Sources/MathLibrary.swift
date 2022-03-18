import simd

let π = Float.pi

public typealias int2 = SIMD2<Int32>
public typealias float2 = SIMD2<Float>
public typealias float3 = SIMD3<Float>
public typealias float4 = SIMD4<Float>

extension Float {
  var radiansToDegrees: Float {
    return (self / π) * 180
  }
  var degreesToRadians: Float {
    return (self / 180) * π
  }
}

extension float4x4 {
  init(translation: float3) {
    let matrix = float4x4(
      [            1,             0,             0, 0],
      [            0,             1,             0, 0],
      [            0,             0,             1, 0],
      [translation.x, translation.y, translation.z, 1]
    )
    self = matrix
  }

  init(scaling: float3) {
    let matrix = float4x4(
      [scaling.x,         0,         0, 0],
      [        0, scaling.y,         0, 0],
      [        0,         0, scaling.z, 0],
      [        0,         0,         0, 1]
    )
    self = matrix
  }

  public init(scaling: Float) {
    self = matrix_identity_float4x4
    columns.3.w = 1 / scaling
  }
  
  init(rotationX angle: Float) {
    let matrix = float4x4(
      [1,           0,          0, 0],
      [0,  cos(angle), sin(angle), 0],
      [0, -sin(angle), cos(angle), 0],
      [0,           0,          0, 1]
    )
    self = matrix
  }
  
  init(rotationY angle: Float) {
    let matrix = float4x4(
      [cos(angle), 0, -sin(angle), 0],
      [         0, 1,           0, 0],
      [sin(angle), 0,  cos(angle), 0],
      [         0, 0,           0, 1]
    )
    self = matrix
  }
  
  init(rotationZ angle: Float) {
    let matrix = float4x4(
      [ cos(angle), sin(angle), 0, 0],
      [-sin(angle), cos(angle), 0, 0],
      [          0,          0, 1, 0],
      [          0,          0, 0, 1]
    )
    self = matrix
  }

  init(rotation angle: float3) {
    let rotationX = float4x4(rotationX: angle.x)
    let rotationY = float4x4(rotationY: angle.y)
    let rotationZ = float4x4(rotationZ: angle.z)
    self = rotationX * rotationY * rotationZ
  }
  
  public static func identity() -> float4x4 {
    let matrix:float4x4 = matrix_identity_float4x4
    return matrix
  }
  
  public init(projectionFov fov: Float, near: Float, far: Float, aspect: Float) {
    let y = 1 / tan(fov * 0.5)
    let x = y / aspect
    let z = far / (near - far)
    self.init(columns: (
        float4( x,  0,  0,  0),
        float4( 0,  y,  0,  0),
        float4( 0,  0,  z, -1),
        float4( 0,  0,  z * near,  0)
    ))
  }
  
  
}
