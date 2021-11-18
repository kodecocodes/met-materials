import simd

public struct Transform {
  public var position: float3 = [0, 0, 0]
  public var rotation: float3 = [0, 0, 0]
  public var scale: float3 = [1, 1, 1]

  public var matrix: float4x4 {
    let translateMatrix = float4x4(translation: position)
    let rotateMatrix = float4x4(rotation: rotation)
    let scaleMatrix = float4x4(scaling: scale)
    return translateMatrix * rotateMatrix * scaleMatrix
  }
  
  public init() {}
}
