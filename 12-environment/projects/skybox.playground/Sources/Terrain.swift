import MetalKit

public class Terrain {
  var name = "Terrain"
  
  public let vertices: [Float] = [
    -1,  1, 0,
    -1, -1, 0,
     1, -1, 0,
     1, -1, 0,
     1,  1, 0,
    -1,  1, 0
  ]
  public let uvs: [Float] = [
    0, 0,
    0, 1,
    1, 1,
    1, 1,
    1, 0,
    0, 0
  ]
  
  public var buffer: MTLBuffer
  public var uvBuffer: MTLBuffer
  public var texture: MTLTexture?
  public var pipelineState: MTLRenderPipelineState!
  public var samplerState: MTLSamplerState!
  public weak var device: MTLDevice?

  public var position: float3 = [0, 0, 0]
  public var rotation: float3 = [0, 0, 0]
  public var scale: float3 = [1, 1, 1]
  
  public var modelMatrix: float4x4 {
    let translateMatrix = float4x4(translation: position)
    let rotateMatrix = float4x4(rotation: rotation)
    let scaleMatrix = float4x4(scaling: scale)
    return translateMatrix * scaleMatrix * rotateMatrix
  }
  
  public init(device: MTLDevice) {
    self.device = device
    buffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: [])!
    uvBuffer = device.makeBuffer(bytes: uvs, length: uvs.count * MemoryLayout<Float>.size, options: [])!
  }
}
