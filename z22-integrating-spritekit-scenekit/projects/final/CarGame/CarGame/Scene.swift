//
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


import Foundation
import CoreGraphics

class Scene {
  let inputController = InputController()
  let physicsController = PhysicsController()
  var skybox: Skybox?
  
  var sceneSize: CGSize
  var cameras = [Camera()]
  var currentCameraIndex = 0
  var camera: Camera  {
    return cameras[currentCameraIndex]
  }
  
  var postProcessNodes: [PostProcess] {
    return allNodes.compactMap { $0 as? PostProcess }
  }
  
  init(sceneSize: CGSize) {
    self.sceneSize = sceneSize
    setupScene()
    sceneSizeWillChange(to: sceneSize)
  }
  
  let rootNode = Node()
  var renderables: [Renderable] = []
  var allNodes: [Node] = []

  var uniforms = Uniforms()
  var fragmentUniforms = FragmentUniforms()
  
  func setupScene() {
    // override this to add objects to the scene
  }
  
  private func updatePlayer(deltaTime: Float) {
    guard let node = inputController.player else { return }
    let holdPosition = node.position
    let holdRotation = node.rotation
    inputController.updatePlayer(deltaTime: deltaTime)
    if physicsController.checkCollisions() && !updateCollidedPlayer() {
      node.position = holdPosition
      node.rotation = holdRotation
    }
  }
  
  func updateCollidedPlayer() -> Bool {
    // override this
    return false
  }
  
  final func update(deltaTime: Float) {
    updatePlayer(deltaTime: deltaTime)
    
    uniforms.projectionMatrix = camera.projectionMatrix
    uniforms.viewMatrix = camera.viewMatrix
    fragmentUniforms.cameraPosition = camera.position
    
    updateScene(deltaTime: deltaTime)
    update(nodes: rootNode.children, deltaTime: deltaTime)
  }
  
  private func update(nodes: [Node], deltaTime: Float) {
    nodes.forEach { node in
      node.update(deltaTime: deltaTime)
      update(nodes: node.children, deltaTime: deltaTime)
    }
  }
  
  func updateScene(deltaTime: Float) {
    // override this to update your scene
  }
  
  final func add(node: Node, parent: Node? = nil, render: Bool = true) {
    if let parent = parent {
      parent.add(childNode: node)
    } else {
      rootNode.add(childNode: node)
    }
    allNodes.append(node)
    guard render == true,
      let renderable = node as? Renderable else {
        return
    }
    renderables.append(renderable)
  }
  
  final func remove(node: Node) {
    if let parent = node.parent {
      parent.remove(childNode: node)
    } else {
      for child in node.children {
        child.parent = nil
      }
      node.children = []
    }
    guard let allNodesIndex = (allNodes.firstIndex {
      $0 === node
    }) else { return }
    allNodes.remove(at: allNodesIndex)

    guard node is Renderable,
      let index = (renderables.firstIndex {
        $0 as? Node === node
      }) else { return }
    renderables.remove(at: index)
  }
  
  func sceneSizeWillChange(to size: CGSize) {
    for camera in cameras {
      camera.aspect = Float(size.width / size.height)
    }
    sceneSize = size
  }
}

