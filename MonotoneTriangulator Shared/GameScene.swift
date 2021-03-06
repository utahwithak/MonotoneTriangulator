//
//  GameScene.swift
//  MonotoneTriangulator Shared
//
//  Created by Carl Wieland on 2/20/20.
//  Copyright © 2020 Datum Apps. All rights reserved.
//

import SpriteKit
import TriangulationAlgorithms

class GameScene: SKScene {

    var points = [CGPoint]()

    var monotone = false

    fileprivate var spinnyNode : SKShapeNode?

    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFill
        
        return scene
    }
    
    func setUpScene() {
        // Get label node from scene and store it for use later

        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 4.0
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))

        }
    }
    
    #if os(watchOS)
    override func sceneDidLoad() {
        self.setUpScene()
    }
    #else
    override func didMove(to view: SKView) {
        self.setUpScene()
    }
    #endif

    func makeSpinny(at pos: CGPoint, color: SKColor) {
        var addPoint = true
        if let last = points.last {
            let dx = pos.x - last.x
            let dy = pos.y - last.y
            if sqrt((dx * dx) + (dy * dy) ) < 100 {
                addPoint = false
            }
        }

        if addPoint {
            let node = SKShapeNode(circleOfRadius: 3)
            node.position = pos
            addChild(node)
            points.append(pos)
        }

    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}

#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        for t in touches {
            self.makeSpinny(at: t.location(in: self), color: SKColor.green)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.makeSpinny(at: t.location(in: self), color: SKColor.blue)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.makeSpinny(at: t.location(in: self), color: SKColor.red)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.makeSpinny(at: t.location(in: self), color: SKColor.red)
        }
    }
    

}
#endif

#if os(OSX)
// Mouse-based event handling
extension GameScene {

    override func mouseDown(with event: NSEvent) {
        points.removeAll(keepingCapacity: true)
        self.removeAllChildren()
    }
    
    override func mouseDragged(with event: NSEvent) {
        self.makeSpinny(at: event.location(in: self), color: SKColor.blue)
    }
    
    override func mouseUp(with event: NSEvent) {
        //        self.makeSpinny(at: event.location(in: self), color: SKColor.red)
        if points.count > 3 {

            do {

                let triangles: [Int]
                if monotone || event.modifierFlags.contains(.command) {
                    triangles = try MonotonePolygonAlgorithm.triangulate(points: points)
                } else {
                    var io = TriangulateIO()
                    io.pointlist = points
                    var behavior = Behavior()
                    //        behavior.verbose = true
                    //        behavior.convex = true
                    behavior.dwyer = true
                    behavior.usesegments = true
                    behavior.poly = true

                    io.segmentlist = [Int](repeating: 0, count: io.pointlist.count * 2)
                    for  i in 0..<io.pointlist.count {
                        io.segmentlist[i * 2] = i
                        io.segmentlist[(i * 2) + 1] = i + 1
                    }
                    io.segmentlist[ io.pointlist.count * 2 - 1] = 0
                    let out = Triangulator.triangulate(b: behavior, inArgs: io)
                    self.points = out.pointlist.map { CGPoint(x: $0.x, y: $0.y) }
                    triangles = out.trianglelist
                }
                for i in stride(from: 0, to: triangles.count, by: 3) where i + 2 < triangles.count && triangles[i + 2] < points.count {
                    let path = CGMutablePath()
                    path.move(to: points[triangles[i]])
                    path.addLine(to: points[triangles[i + 1]])
                    path.addLine(to: points[triangles[i + 2]])
                    path.closeSubpath()
                    let line = SKShapeNode(path: path)
                    addChild(line)
                }

            } catch {
                print("Failed to triangulate!")
            }
        }
    }

}
#endif

