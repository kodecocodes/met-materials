//
/**
 * Copyright (c) 2018 Razeware LLC
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


import MetalKit

extension Renderer {
  func loadAsset(name: String, position: float3, scale: Float) {
    let assetURL = Bundle.main.url(forResource: name, withExtension: "obj")!
    let allocator = MTKMeshBufferAllocator(device: device)
    let asset = MDLAsset(url: assetURL,
                         vertexDescriptor: vertexDescriptor,
                         bufferAllocator: allocator)
    guard let mdlMesh = asset.object(at: 0) as? MDLMesh,
      let mdlSubmeshes = mdlMesh.submeshes as? [MDLSubmesh] else { return }
    let mesh = try! MTKMesh(mesh: mdlMesh, device: device)
    let count = mesh.vertexBuffers[0].buffer.length / MemoryLayout<float3>.size
    let positionBuffer = mesh.vertexBuffers[0].buffer
    let normalsBuffer = mesh.vertexBuffers[1].buffer
    let normalsPtr = normalsBuffer.contents().bindMemory(to: float3.self, capacity: count)
    let positionPtr = positionBuffer.contents().bindMemory(to: float3.self, capacity: count)
    for (mdlIndex, submesh) in mesh.submeshes.enumerated() {
      let indexBuffer = submesh.indexBuffer.buffer
      let offset = submesh.indexBuffer.offset
      let indexPtr = indexBuffer.contents().advanced(by: offset)
      var indices = indexPtr.bindMemory(to: uint.self, capacity: submesh.indexCount)
      for _ in 0..<submesh.indexCount {
        let index = Int(indices.pointee)
        vertices.append(positionPtr[index] * scale + position)
        normals.append(normalsPtr[index])
        indices = indices.advanced(by: 1)
        let mdlSubmesh = mdlSubmeshes[mdlIndex]
        let color: float3
        if let baseColor = mdlSubmesh.material?.property(with: .baseColor),
          baseColor.type == .float3 {
          color = baseColor.float3Value
        } else {
          color = [1, 0, 0]
        }
        colors.append(color)
      }
    }
  }

}
