import MetalKit

struct Particle {
  var position: float2
  var direction: Float
  var speed: Float
  var color: float3
  var life: Float
  
}

public struct Emitter {
  public let particleBuffer: MTLBuffer
  
  public init(particleCount: Int, size: CGSize,
              life: Float, device: MTLDevice) {
    let bufferSize = MemoryLayout<Particle>.stride * particleCount
    particleBuffer = device.makeBuffer(length: bufferSize)!
 
    var pointer = particleBuffer.contents().bindMemory(to: Particle.self,
                                                       capacity: particleCount)
    let width = Float(size.width)
    let height = Float(size.height)
    let position = float2(Float.random(in: 0...width),
                          Float.random(in: 0...height))
    let color = float3(Float.random(in: 0...life) / life,
                       Float.random(in: 0...life) / life,
                       Float.random(in: 0...life) / life)
    
    for _ in 0..<particleCount {
      let direction = 2 * Float.pi * Float.random(in: 0...width) / width
      let speed = 3 * Float.random(in: 0...width) / width
      pointer.pointee.position = position
      pointer.pointee.direction = direction
      pointer.pointee.speed = speed
      pointer.pointee.color = color
      pointer.pointee.life = life
      pointer = pointer.advanced(by: 1)
    }
  }
}


