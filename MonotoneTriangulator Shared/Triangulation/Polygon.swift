//
//  Polygon.swift
//  TriExploration
//
//  Created by Carl Wieland on 10/11/16.
//  Copyright © 2016 Datum Apps. All rights reserved.
//

import Foundation

enum Orientation {
    case Clockwise
    case CounterClockwise
}

struct Polygon {

    init(points: [Vector2]) {
        var verts = [MonotonePolygonAlgorithm.Vertex]()

        let initial = MonotonePolygonAlgorithm.Vertex(point: points[0])
        verts.append(initial)

        var start = initial
        for i in 1..<points.count {
            let end = MonotonePolygonAlgorithm.Vertex(point: points[i])
            verts.append(end)
            let e1 = Edge(origin: start)
            let e2 = Edge(origin: end)
            end.outEdge = e2
            e1.pairWith(edge: e2)
            if let startOut = start.outEdge {
                e2.next = startOut
                e2.next.prev = e2
                e1.prev = startOut.pair
                e1.prev.next = e1
            }
            start.outEdge = e1
            start = end
        }

        let bridge = Edge(origin: initial)
        let bridgePair = Edge(origin: start)
        bridge.pairWith(edge: bridgePair)

        // Hook up nexts
        //
        bridgePair.next = initial.outEdge
        initial.outEdge!.prev = bridgePair

        start.outEdge!.prev = bridge;
        bridge.next = start.outEdge;

        // hook up prevs
        //
        bridge.prev = initial.outEdge!.pair;
        initial.outEdge!.pair.next = bridge;

        bridgePair.prev = start.outEdge!.pair;
        start.outEdge!.pair.next = bridgePair;
        start.outEdge = bridgePair

        // Determine which side should have the initial pointer.
        //

        if Polygon.orientationOf(points: points) == .CounterClockwise {
            self.init(startEdge: bridgePair, vertices: verts)
        } else {
            self.init(startEdge: bridge, vertices: verts)
        }

        flipOutEdges()


    }

    static func orientationOf(points: [Vector2]) -> Orientation {
        let n = points.count
        var A = 0.0
        for q in 0..<n {
            let p = q == 0 ? n - 1 : q - 1
            let P = points[p]
            let Q = points[q]
            A += P.x * Q.y - Q.x * P.y;
        }
        return  A > 0 ? .CounterClockwise : .Clockwise;
    }

    private init(startEdge: Edge, vertices: [MonotonePolygonAlgorithm.Vertex]) {
        self.startEdge = startEdge
        self.vertices = vertices
    }

    let startEdge: Edge
    var vertices: [MonotonePolygonAlgorithm.Vertex]

    func flipOutEdges() {
        var runner = self.startEdge;
        repeat {
            runner.start.outEdge = runner;
            runner = runner.next;
        } while runner !== self.startEdge ;

    }

    var eventPoints: [MonotonePolygonAlgorithm.Vertex] {
        return vertices
    }

    var startEdges: [Edge] {
        var toVisit = [startEdge]
        var visted = Set<Edge>()
        var startPoints = [Edge]()

        while let start = toVisit.first {

            startPoints.append(start)

            var runner = start;
            repeat {

                visted.insert(runner);
                toVisit.removeAll(where: { $0 == runner})
                if runner.pair != nil && !visted.contains(runner.pair) {
                    toVisit.append(runner.pair)
                }
                runner = runner.next
            } while runner !== start;

        }
        //remove the loop along the outside.
        //will always be the second one since it will be added from the start edge.
        startPoints.remove(at: 1)
        return startPoints;
    }

    var triangles: [Int] {
        var triangles = [Int]()
        for e in startEdges {
            var runner = e

            repeat {
                triangles.append(self.vertices.firstIndex(of: runner.start)!)
                runner = runner.prev
            } while runner !== e;

            if triangles.count % 3 != 0 {
                print("invalid triangulation!!")
            }
        }
        return triangles
    }

    func addDiagonalFrom(start v1: MonotonePolygonAlgorithm.Vertex, toVertex v2: MonotonePolygonAlgorithm.Vertex) {

        let e1 = Edge(origin: v1)
        let e2 = Edge(origin: v2)
        e1.pairWith(edge: e2)
        v1.connectNew(edge: e1)
        v2.connectNew(edge: e2)
    }

    var subPolygons: [SubPolygon] {
        return startEdges.map({ return SubPolygon(startEdge: $0) })
    }

}

struct SubPolygon {
    let startEdge: Edge

    func edgeStarting(at start: MonotonePolygonAlgorithm.Vertex) -> Edge? {
        var runner = startEdge
        repeat {
            if runner.start == start {
                return runner
            } else {
                runner = runner.next
            }
        } while runner != startEdge
        return nil
    }
}
