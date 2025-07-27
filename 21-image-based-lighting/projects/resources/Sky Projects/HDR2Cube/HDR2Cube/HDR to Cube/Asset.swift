///// Copyright (c) 2025 Kodeco Inc.
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

import Foundation
import AppKit
import MetalKit

class Asset {

  let id: String
  let file: URL?
  var textures: [String : NSImage] = [:]

  init(file: URL) {
    _ = file.startAccessingSecurityScopedResource()
    self.id = file.absoluteString
    self.file = file
  }

  deinit {
    file?.stopAccessingSecurityScopedResource()
  }

  var name: String {
    return self.file?.lastPathComponent ?? self.id
  }
}

extension Asset {

  static func load(from fileURL: URL) -> Asset {
    let asset = Asset(file: fileURL)
    asset.textures = createCubemap(from: asset)
    return asset
  }

  static func createCubemap(from asset: Asset, outputSize: Int = 512) -> [String: NSImage]{
    let empty: [String: NSImage] = [:]

    guard let url = asset.file,
          let device = MTLCreateSystemDefaultDevice(),
          let commandQueue = device.makeCommandQueue() else { return empty }

    let textureLoader = MTKTextureLoader(device: device)
    let options: [MTKTextureLoader.Option: Any] = [
      .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
      .textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue),
      .SRGB: false
    ]
    let hdrTexture = try! textureLoader.newTexture(URL: url, options: options)

    let library = device.makeDefaultLibrary()!
    let pso = try! makeRenderPipeline(device: device, library: library)

    let directions: [(name: String, direction: simd_float3, up: simd_float3)] = [
      ("posX", [1, 0, 0], [0, -1, 0]),
      ("negX", [-1, 0, 0], [0, -1, 0]),
      ("posY", [0, 1, 0], [0, 0, 1]),
      ("negY", [0, -1, 0], [0, 0, -1]),
      ("posZ", [0, 0, 1], [0, -1, 0]),
      ("negZ", [0, 0, -1], [0, -1, 0])
    ]

    var textures = [String: NSImage]()

    for face in directions {
      let faceTexture = makeCubemapTexture(
        device: device,
        size: outputSize)
      let viewMatrix = lookAt(
        eye: [0, 0, 0],
        center: face.direction,
        up: face.up)
      let projectionMatrix = perspectiveFov(fovY: Float.pi / 2, aspect: 1.0, nearZ: 0.1, farZ: 10.0)
      renderCubemapFace(
        device: device,
        commandQueue: commandQueue,
        pipelineState: pso,
        eqTexture: hdrTexture,
        outputTexture: faceTexture,
        viewMatrix: viewMatrix,
        projectionMatrix: projectionMatrix)

      textures[face.name] = textureToNSImage(faceTexture)
    }
    return textures
  }

  static func textureToNSImage(_ texture: MTLTexture) -> NSImage? {
    guard texture.pixelFormat == .bgra8Unorm || texture.pixelFormat == .rgba8Unorm else {
      print("Unsupported pixel format")
      return nil
    }

    let width = texture.width
    let height = texture.height
    let bytesPerPixel = 4
    let unalignedBytesPerRow = width * bytesPerPixel
    let bytesPerRow = ((unalignedBytesPerRow + 255) / 256) * 256 // align to 256

    let dataSize = bytesPerRow * height
    var rawData = [UInt8](repeating: 0, count: dataSize)

    let region = MTLRegionMake2D(0, 0, width, height)
    texture.getBytes(
      &rawData,
      bytesPerRow: bytesPerRow,
      from: region,
      mipmapLevel: 0)

    guard let bitmapRep = NSBitmapImageRep(
      bitmapDataPlanes: nil,
      pixelsWide: width,
      pixelsHigh: height,
      bitsPerSample: 8,
      samplesPerPixel: 4,
      hasAlpha: true,
      isPlanar: false,
      colorSpaceName: .deviceRGB,
      bytesPerRow: bytesPerRow,
      bitsPerPixel: 32) else {
      return nil
    }
    memcpy(bitmapRep.bitmapData, rawData, dataSize)
    let image = NSImage(size: NSSize(width: width, height: height))
    image.addRepresentation(bitmapRep)
    return image
  }

  static func makeCubemapTexture(device: MTLDevice, size: Int) -> MTLTexture {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .rgba8Unorm,
      width: size,
      height: size,
      mipmapped: false)
    descriptor.usage = [.shaderRead, .renderTarget]
    return device.makeTexture(descriptor: descriptor)!
  }

  static func makeRenderPassDescriptor(texture: MTLTexture) -> MTLRenderPassDescriptor {
    let rpd = MTLRenderPassDescriptor()
    rpd.colorAttachments[0].texture = texture
    rpd.colorAttachments[0].storeAction = .store
    return rpd
  }

  static func makeRenderPipeline(device: MTLDevice, library: MTLLibrary) throws -> MTLRenderPipelineState {
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.vertexFunction = library.makeFunction(name: "vertex_main")
    descriptor.fragmentFunction = library.makeFunction(name: "fragment_main")
    descriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
    return try device.makeRenderPipelineState(descriptor: descriptor)
  }

  static func renderCubemapFace(
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    pipelineState: MTLRenderPipelineState,
    eqTexture: MTLTexture,
    outputTexture: MTLTexture,
    viewMatrix: simd_float4x4,
    projectionMatrix: simd_float4x4
  ) {
    let rpd = makeRenderPassDescriptor(texture: outputTexture)
    guard let commandBuffer = commandQueue.makeCommandBuffer(),
          let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd)
    else { return }
    encoder.setRenderPipelineState(pipelineState)

    let viewProjection = projectionMatrix * viewMatrix
    var inverseViewProjection = viewProjection.inverse
    encoder.setVertexBytes(
      &inverseViewProjection,
      length: MemoryLayout<simd_float4x4>.stride,
      index: 0)

    encoder.setFragmentTexture(eqTexture, index: 0)

    // 6 fullscreen quad vertices
    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)

    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
  }

  static func lookAt(eye: simd_float3, center: simd_float3, up: simd_float3) -> simd_float4x4 {
    let f = simd_normalize(center - eye)
    let s = simd_normalize(simd_cross(f, up))
    let u = simd_cross(s, f)

    var result = matrix_identity_float4x4
    result.columns.0 = simd_float4(s, 0)
    result.columns.1 = simd_float4(u, 0)
    result.columns.2 = simd_float4(-f, 0)
    result.columns.3 = simd_float4(0, 0, 0, 1)
    return result
  }

  static func perspectiveFov(fovY: Float, aspect: Float, nearZ: Float, farZ: Float) -> simd_float4x4 {
    let yScale = 1.0 / tan(fovY * 0.5)
    let xScale = yScale / aspect
    let zRange = farZ - nearZ
    let zScale = -(farZ + nearZ) / zRange
    let wzScale = -2 * farZ * nearZ / zRange

    return simd_float4x4(columns: (
      simd_float4(xScale, 0, 0, 0),
      simd_float4(0, yScale, 0, 0),
      simd_float4(0, 0, zScale, -1),
      simd_float4(0, 0, wzScale, 0)
    ))
  }
}
