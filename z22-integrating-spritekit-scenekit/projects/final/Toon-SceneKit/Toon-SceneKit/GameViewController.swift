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

import SceneKit
import QuartzCore

class GameViewController: NSViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // create a new scene
    let scene = SCNScene(named: "art.scnassets/ship.scn")!
    
    // create and add a camera to the scene
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    scene.rootNode.addChildNode(cameraNode)
    
    // place the camera
    cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
    
    // create and add a light to the scene
    let lightNode = SCNNode()
    lightNode.light = SCNLight()
    lightNode.light!.type = .omni
    lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
    scene.rootNode.addChildNode(lightNode)
    
    // create and add an ambient light to the scene
    let ambientLightNode = SCNNode()
    ambientLightNode.light = SCNLight()
    ambientLightNode.light!.type = .ambient
    ambientLightNode.light!.color = NSColor.darkGray
    scene.rootNode.addChildNode(ambientLightNode)
    
    // retrieve the ship node
    let ship = scene.rootNode.childNode(withName: "ship", recursively: true)!
    
    let program = SCNProgram()
    program.vertexFunctionName = "shipVertex"
    program.fragmentFunctionName = "shipFragment"
    if let material = ship.childNodes[0].geometry?.firstMaterial {
      material.program = program
      if let url = Bundle.main.url(forResource: "art.scnassets/texture",
                                   withExtension: "png") {
        if let texture = NSImage(contentsOf: url) {
          material.setValue(SCNMaterialProperty(contents: texture),
                            forKey: "baseColorTexture")
        }
      }
      let lightPosition = lightNode.position
      material.setValue(lightPosition, forKey: "lightPosition")
    }
    
    ship.eulerAngles = SCNVector3(1, 0.7, 0.9)
    
    // retrieve the SCNView
    let scnView = self.view as! SCNView
    
    // set the scene to the view
    scnView.scene = scene
    
    // allows the user to manipulate the camera
    scnView.allowsCameraControl = true
    
    // show statistics such as fps and timing information
    scnView.showsStatistics = true
    
    // configure the view
    scene.background.contents = nil
    scnView.backgroundColor = NSColor(calibratedWhite: 0.9, alpha: 1.0)

    // Add a click gesture recognizer
    let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
    var gestureRecognizers = scnView.gestureRecognizers
    gestureRecognizers.insert(clickGesture, at: 0)
    scnView.gestureRecognizers = gestureRecognizers
  }
  
  @objc
  func handleClick(_ gestureRecognizer: NSGestureRecognizer) {
    // retrieve the SCNView
    let scnView = self.view as! SCNView
    
    // check what nodes are clicked
    let p = gestureRecognizer.location(in: scnView)
    let hitResults = scnView.hitTest(p, options: [:])
    // check that we clicked on at least one object
    if hitResults.count > 0 {
      // retrieved the first clicked object
      let result = hitResults[0]
      
      // get its material
      let material = result.node.geometry!.firstMaterial!
      
      // highlight it
      SCNTransaction.begin()
      SCNTransaction.animationDuration = 0.5
      
      // on completion - unhighlight
      SCNTransaction.completionBlock = {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        
        material.emission.contents = NSColor.black
        
        SCNTransaction.commit()
      }
      
      material.emission.contents = NSColor.red
      
      SCNTransaction.commit()
    }
  }
}
