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

    var edges = [Edge]()
    let vertices: [MonotonePolygonAlgorithm.Vertex]
    var startEdge = 0

    init(points: [Vector2]) {
        // Determine which side should have the initial pointer.
        //
        self.vertices = points.enumerated().map({MonotonePolygonAlgorithm.Vertex(point: $0.1, id: $0.0)})

        let initial = vertices[0]


        var start = initial
        for i in 1..<points.count {
            let end = vertices[i]
            let e1 = Edge(id: edges.count, origin: start.id)
            edges.append(e1)
            let e2 = Edge(id: edges.count, origin: end.id)
            edges.append(e2)
            end.outEdge = e2.id
            e1.pairWith(edge: e2, polygon: self)
            if start.outEdge >= 0 {

                e2.next = start.outEdge
                edges[e2.next].prev = e2.id
                e1.prev = edges[start.outEdge].pair
                edges[e1.prev].next = e1.id
            }
            start.outEdge = e1.id
            start = end
        }

        let bridge = Edge(id: edges.count, origin: initial.id)
        edges.append(bridge)
        let bridgePair = Edge(id: edges.count, origin: start.id)
        edges.append(bridgePair)
        bridge.pairWith(edge: bridgePair, polygon: self)

        // Hook up nexts
        //
        bridgePair.next = initial.outEdge
        edges[initial.outEdge].prev = bridgePair.id

        edges[start.outEdge].prev = bridge.id;
        bridge.next = start.outEdge;

        // hook up prevs
        //
        bridge.prev = edges[initial.outEdge].pair;
        edges[edges[initial.outEdge].pair].next = bridge.id

        bridgePair.prev = edges[start.outEdge].pair
        edges[edges[start.outEdge].pair].next = bridgePair.id
        start.outEdge = bridgePair.id

        if Polygon.orientationOf(points: points) == .CounterClockwise {
            self.startEdge = bridgePair.id
        } else {
            self.startEdge = bridge.id
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
        return A > 0 ? .CounterClockwise : .Clockwise;
    }

    func flipOutEdges() {
        var runner = edges[startEdge];
        repeat {
            vertices[runner.start].outEdge = runner.id;
            runner = edges[runner.next]
        } while runner != edges[startEdge]

    }

    func next(_ id: Int) -> Int {
        return edges[id].next
    }
    func prev(_ id: Int) -> Int {
    return edges[id].prev
    }

    var startEdges: [Int] {
        var toVisit = [startEdge]
        var visted = Set<Int>()
        var startPoints = [Int]()

        while let start = toVisit.first {
            startPoints.append(start)

            var runner = start;
            repeat {

                visted.insert(runner);
                toVisit.removeAll(where: { $0 == runner})
                if edges[runner].pair >= 0 && !visted.contains(edges[runner].pair) {
                    toVisit.append(edges[runner].pair)
                }
                runner = edges[runner].next
            } while runner != start;

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
                triangles.append(edges[runner].start)
                runner = edges[runner].prev
            } while runner != e;

            if triangles.count % 3 != 0 {
                print("invalid triangulation!!")
            }
        }
        return triangles
    }

    mutating func addDiagonalFrom(start v1: MonotonePolygonAlgorithm.Vertex, toVertex v2: MonotonePolygonAlgorithm.Vertex) {

        let e1 = Edge(id: edges.count, origin: v1.id)
        edges.append(e1)
        let e2 = Edge(id: edges.count, origin: v2.id)
        edges.append(e2)
        e1.pairWith(edge: e2, polygon: self)
        v1.connectNew(edge: e1, polygon: self)
        v2.connectNew(edge: e2, polygon: self)
    }

    var subPolygons: [SubPolygon] {
        return startEdges.map({ return SubPolygon(startEdge: edges[$0]) })
    }

}

struct SubPolygon {
    let startEdge: Edge

    func edgeStarting(at start: MonotonePolygonAlgorithm.Vertex, polygon: Polygon) -> Edge? {
        var runner = startEdge
        repeat {
            if runner.start == start.id {
                return runner
            } else {
                runner = polygon.edges[runner.next]
            }
        } while runner != startEdge
        return nil
    }
}
