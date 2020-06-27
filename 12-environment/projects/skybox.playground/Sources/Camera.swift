import MetalKit

public class Camera {
  public var near: Float = 0.1
  public var far: Float = 100
  public var aspect: Float = 1
  public var fov: Float = Float(60).degreesToRadians

  public var projectionMatrix: float4x4 {
    return float4x4(projectionFov: fov,
                    near: near,
                    far: far,
                    aspect: aspect)
  }
  
  public init() {}
  
  public init(near: Float, far: Float, aspect: Float, fov: Float = 1.135) {
    self.near = near
    self.far = far
    self.aspect = aspect
    self.fov = fov
  }

  public var viewMatrix = float4x4.identity()
  public var transform = Transform() {
    didSet {
      let translateMatrix = float4x4(translation: [-transform.position.x, -transform.position.y, -transform.position.z])
      let translateBackMatrix = float4x4(translation: transform.position)
      let rotateMatrix = float4x4(rotation: transform.rotation)
      let scaleMatrix = float4x4(scaling: transform.scale)
      viewMatrix =  translateMatrix * translateBackMatrix * rotateMatrix * translateMatrix * scaleMatrix
    }
  }
}

