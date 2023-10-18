///// Copyright (c) 2023 Kodeco Inc.
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

import MetalKit

// swiftlint:disable force_try

class Model: Transformable {
  var transform = Transform()
  var meshes: [Mesh] = []
  var name: String = "Untitled"
  var tiling: UInt32 = 1
  var hasTransparency = false
  var boundingBox = MDLAxisAlignedBoundingBox()
  var size: float3 {
    return boundingBox.maxBounds - boundingBox.minBounds
  }

  var currentTime: Float = 0

  var skeleton: Skeleton?
  var animationClips: [String: AnimationClip] = [:]
  var pipelineState: MTLRenderPipelineState?
  var modelParams = ModelParams()

  init() {}

  init(name: String) {
    guard let assetURL = Bundle.main.url(
      forResource: name,
      withExtension: nil) else {
      fatalError("Model \(name) not found")
    }
    let allocator = MTKMeshBufferAllocator(device: Renderer.device)
    let asset = MDLAsset(
      url: assetURL,
      vertexDescriptor: .defaultLayout,
      bufferAllocator: allocator)
    asset.loadTextures()
    var mtkMeshes: [MTKMesh] = []
    let mdlMeshes =
    asset.childObjects(of: MDLMesh.self) as? [MDLMesh] ?? []
    _ = mdlMeshes.map { mdlMesh in
      mtkMeshes.append(
        try! MTKMesh(
          mesh: mdlMesh,
          device: Renderer.device))
    }
    meshes = zip(mdlMeshes, mtkMeshes).map {
      Mesh(
        mdlMesh: $0.0,
        mtkMesh: $0.1,
        startTime: asset.startTime,
        endTime: asset.endTime)
    }
    self.name = name
    boundingBox = asset.boundingBox

    // load animated characters
    loadSkeleton(asset: asset)
    loadSkins(mdlMeshes: mdlMeshes)
    loadAnimations(asset: asset)

    let hasSkeleton = skeleton != nil
    pipelineState = PipelineStates.createForwardPSO(hasSkeleton: hasSkeleton)

  }

  func loadSkeleton(asset: MDLAsset) {
    let skeletons =
    asset.childObjects(of: MDLSkeleton.self) as? [MDLSkeleton] ?? []
    skeleton = Skeleton(mdlSkeleton: skeletons.first)
  }

  func loadSkins(mdlMeshes: [MDLMesh]) {
    for index in 0..<mdlMeshes.count {
      let animationBindComponent =
      mdlMeshes[index].componentConforming(to: MDLComponent.self)
      as? MDLAnimationBindComponent
      guard let skeleton else { continue }
      let skin = Skin(
        animationBindComponent: animationBindComponent,
        skeleton: skeleton)
      meshes[index].skin = skin
    }
  }

  func loadAnimations(asset: MDLAsset) {
    let assetAnimations = asset.animations.objects.compactMap {
      $0 as? MDLPackedJointAnimation
    }
    for assetAnimation in assetAnimations {
      let animationClip = AnimationClip(animation: assetAnimation)
      animationClips[assetAnimation.name] = animationClip
    }
  }
  func update(deltaTime: Float) {
    currentTime += deltaTime

    if let skeleton,
       let animation = animationClips.first {
      let animationClip = animation.value
      skeleton.updatePose(
        at: currentTime,
        animationClip: animationClip)
    }

    for index in 0..<meshes.count {
      var mesh = meshes[index]
      mesh.transform?.getCurrentTransform(at: currentTime)
      mesh.skin?.updatePalette(skeleton: skeleton)
      meshes[index] = mesh
    }
  }
}

extension Model {
  func setTexture(name: String, type: TextureIndices) {
    if let texture = TextureController.texture(name: name) {
      switch type {
      case BaseColor:
        meshes[0].submeshes[0].textures.baseColor = texture
      default: break
      }
    }
  }
}
// swiftlint:enable force_try
