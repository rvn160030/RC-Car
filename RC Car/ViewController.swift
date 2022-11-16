//
//  ViewController.swift
//  RC Car
//
//  Vincent Noble RVN160030
//  CS4392.001 Computer Animation
//  03 December 2018
//  "Red Car" object by Jarlan Perez, (CC-BY) 2017 (see references in report)
//  Toy Car Mat image from eBay (see references in report)

import UIKit
import SceneKit
import ARKit

enum BodyType: Int {
    case car = 1
    case plane = 2
    case barrier = 4
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    private var planeNode: SCNNode!
    
    private var kartNode: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true
        
        // Create scene for go kart
        let goKartScene = SCNScene(named: "car.dae")
        guard let kart = goKartScene?.rootNode.childNode(withName: "car", recursively: true) else { return }
        kartNode = SCNNode()
        kartNode.addChildNode(kart)
        // Add physics to go kart
        // Create new bounding box based on scaled size of model
        let min = kartNode.boundingBox.min
        let max = kartNode.boundingBox.max
        let boundingBox = SCNBox(width: CGFloat(max.x - min.x), height: CGFloat(max.y - min.y), length: CGFloat(max.z - min.z), chamferRadius: 0.0)
        // Create and set physicsShape and physicsBody
        let boundingBoxShape = SCNPhysicsShape(geometry: boundingBox, options: nil)
        kartNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: kartNode, options: nil))
        kartNode.physicsBody?.physicsShape = boundingBoxShape
        kartNode.physicsBody?.categoryBitMask = BodyType.car.rawValue
        
        // Set up regular scene
        let scene = SCNScene()
        sceneView.scene = scene
        
        // Set up gesture recognizer for adding kart to scene
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(addKartToSceneTap))
        sceneView.addGestureRecognizer(tapRecognizer)
        
        // Set up D-Pad
        setupDPad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Set up horizontal plane detection
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // Creating the toy mat
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor){
        // Prevent more than one mat from being created
        if(planeNode != nil){ return }
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        // Make plane the toy mat
        let toyMatMaterial = SCNMaterial()
        toyMatMaterial.diffuse.contents = UIImage(named: "mat.jpg")
        plane.materials = [toyMatMaterial]
        
        // Create node
        planeNode = SCNNode(geometry: plane)
        // Position the toy mat
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
        planeNode.eulerAngles.x = -.pi / 2
        
        // Add physics to mat, so kart "collides" with mat
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: plane, options: nil))
        planeNode.physicsBody?.categoryBitMask = BodyType.plane.rawValue
        planeNode.physicsBody?.collisionBitMask = BodyType.car.rawValue
        
        // Add node to scene
        node.addChildNode(planeNode)
        
        // Create barriers for mat
        let barrierTop = createBarrier(dimension: width, isLength: false)
        barrierTop.position = SCNVector3(x, y, z + (height / 2))
        let barrierBottom = createBarrier(dimension: width, isLength: false)
        barrierBottom.position = SCNVector3(x, y, z - (height / 2))
        let barrierLeft = createBarrier(dimension: height, isLength: true)
        barrierLeft.position = SCNVector3(x - (width / 2), y, z)
        let barrierRight = createBarrier(dimension: height, isLength: true)
        barrierRight.position = SCNVector3(x + (width / 2), y, z)
        // Add barriers to scene
        node.addChildNode(barrierTop)
        node.addChildNode(barrierBottom)
        node.addChildNode(barrierRight)
        node.addChildNode(barrierLeft)
        node.addChildNode(barrierLeft)
    }
    
    // Resizing toy mat
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            // Get the plane node
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane else { return }
        
        // Get new size and resize mat
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        // Re-display mat
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
        // Re-instate physics for mat
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: plane, options: nil))
        planeNode.physicsBody?.categoryBitMask = BodyType.plane.rawValue
        planeNode.physicsBody?.collisionBitMask = BodyType.car.rawValue
        // Remove current barriers
        removeBarriers()
        // Recreate barriers for mat, re-position, and reset physics to new pos
        let barrierTop = createBarrier(dimension: width, isLength: false)
        barrierTop.position = SCNVector3(x, y + 0.025, z - (height / 2))
        
        let barrierBottom = createBarrier(dimension: width, isLength: false)
        barrierBottom.position = SCNVector3(x, y + 0.025, z + (height / 2))
        
        let barrierLeft = createBarrier(dimension: height, isLength: true)
        barrierLeft.position = SCNVector3(x - (width / 2), y + 0.025, z)
        
        let barrierRight = createBarrier(dimension: height, isLength: true)
        barrierRight.position = SCNVector3(x + (width / 2), y + 0.025, z)
        // Add barriers to scene
        node.addChildNode(barrierTop)
        node.addChildNode(barrierBottom)
        node.addChildNode(barrierRight)
        node.addChildNode(barrierLeft)
    }
    
    // Tap handler for placing the go kart
    @objc func addKartToSceneTap(withGestruerRecognizer recognizer: UIGestureRecognizer){
        let sceneView = recognizer.view as! ARSCNView
        let location = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        // Extract location of hit w/r to world
        guard let hitResult = hitTestResults.first else { return }
        // Set the position of the kart
        let x = hitResult.worldTransform.columns.3.x
        let y = hitResult.worldTransform.columns.3.y
        let z = hitResult.worldTransform.columns.3.z
        kartNode.physicsBody?.clearAllForces()
        // Prevent the car's position from intersecting the plane
        kartNode.position = SCNVector3(x, y + 0.1, z)
        // Add to scene
        self.sceneView.scene.rootNode.addChildNode(kartNode)
    }
    
    // Add barriers to mat
    private func createBarrier(dimension: CGFloat, isLength: Bool) -> SCNNode{
        let barrier = isLength ? SCNBox(width: 0.02, height: 0.05, length: dimension, chamferRadius: 0.0) : SCNBox(width: dimension, height: 0.05, length: 0.02, chamferRadius: 0.0)
        let barrierMaterial = SCNMaterial()
        barrierMaterial.diffuse.contents = UIImage(named: "BarrierMaterial.png")
        barrier.materials = [barrierMaterial]
        let barrierNode = SCNNode(geometry: barrier)
        barrierNode.name = "barrier"
        // Add physics to barrier for collisions with car
        barrierNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        barrierNode.physicsBody?.categoryBitMask = BodyType.barrier.rawValue
        // Set up collisions with car
        barrierNode.physicsBody?.collisionBitMask = BodyType.car.rawValue
        return barrierNode
    }
    
    // Remove barriers from mat
    private func removeBarriers(){
        sceneView.scene.rootNode.enumerateChildNodes{ (node, _) in
            if node.name == "barrier"{
                node.removeFromParentNode()
            }
        }
    }
    
    // Set up the D-Pad controls
    private func setupDPad(){
        let frameHeight = sceneView.frame.height
        let leftBtn = DPadButton(frame: CGRect(x: 0, y: frameHeight / 3, width: 50, height: 50)){
            self.turnLeft()
        }
        leftBtn.setBackgroundImage(UIImage(named: "LeftBtn.png"), for: .normal)
        
        let rightBtn = DPadButton(frame: CGRect(x: 100, y: frameHeight / 3, width: 50, height: 50)){
            self.turnRight()
        }
        rightBtn.setBackgroundImage(UIImage(named: "RightBtn.png"), for: .normal)
        
        let forwardBtn = DPadButton(frame: CGRect(x: 50, y: frameHeight / 3 - 25, width: 50, height: 50)){
            self.moveForward()
        }
        forwardBtn.setBackgroundImage(UIImage(named: "UpBtn.png"), for: .normal)
        
        let backwardBtn = DPadButton(frame: CGRect(x: 50, y: frameHeight / 3 + 25, width: 50, height: 50)){
            self.moveBackward()
        }
        backwardBtn.setBackgroundImage(UIImage(named: "DownBtn.png"), for: .normal)
        
        
        // Add buttons to view
        sceneView.addSubview(leftBtn)
        sceneView.addSubview(rightBtn)
        sceneView.addSubview(forwardBtn)
        sceneView.addSubview(backwardBtn)
    }
    
    private func turnRight(){
        // Apply torque to turn
        kartNode.physicsBody?.applyTorque(SCNVector4(0.0, 1.0, 0.0, -0.5), asImpulse: false)
    }
    
    private func turnLeft(){
        // Apply torque to turn
        kartNode.physicsBody?.applyTorque(SCNVector4(0.0, 1.0, 0.0, 0.5), asImpulse: false)
    }
    
    private func moveForward(){
        // Create force matrix (move away, so -z)
        let force = simd_make_float4(0.0, 0.0, 5.0, 0.0)
        // Multiply with current kart matrix
        let rotForce = simd_mul(kartNode.presentation.simdTransform, force)
        // Make vector
        let vecForce = SCNVector3(rotForce.x, rotForce.y, rotForce.z)
        // Apply force to kart node
        kartNode.physicsBody?.applyForce(vecForce, asImpulse: false)
    }
    
    private func moveBackward(){
        // Create force matrix (move toward, so z)
        let force = simd_make_float4(0.0, 0.0, -5.0, 0.0)
        // Multiply with current kart matrix
        let rotForce = simd_mul(kartNode.presentation.simdTransform, force)
        // Make vector
        let vecForce = SCNVector3(rotForce.x, rotForce.y, rotForce.z)
        // Apply force to kart node
        kartNode.physicsBody?.applyForce(vecForce, asImpulse: false)
    }
    
}
