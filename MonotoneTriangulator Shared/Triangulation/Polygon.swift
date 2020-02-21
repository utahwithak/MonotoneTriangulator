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
    public private(set) var vertices: [MonotonePolygonAlgorithm.Vertex]
    var startEdge = 0

    init(points: [Vector2]) {
        // Determine which side should have the initial pointer.
        //
        self.vertices = points.enumerated().map({MonotonePolygonAlgorithm.Vertex(point: $0.1, id: $0.0)})

        var start = vertices[0].id
        for i in 1..<points.count {
            let end = vertices[i]
            let eId = edges.count
            let e1 = Edge(id: eId, pairId: eId + 1,  origin: start)
            let e2 = Edge(id: eId + 1, pairId: eId, origin: end.id)
            edges.append(e1)
            edges.append(e2)
            vertices[i].outEdge = e2.id
            e1.pairWith(edge: e2, polygon: self)
            if vertices[start].outEdge >= 0 {

                e2.next = vertices[start].outEdge
                edges[e2.next].prev = e2.id
                e1.prev = edges[vertices[start].outEdge].pair
                edges[e1.prev].next = e1.id
            }
            vertices[start].outEdge = e1.id
            start = end.id
        }
        let eId = edges.count
        let bridge = Edge(id: eId, pairId: eId + 1, origin: 0)
        edges.append(bridge)
        let bridgePair = Edge(id: eId + 1, pairId: eId, origin: start)
        edges.append(bridgePair)
        bridge.pairWith(edge: bridgePair, polygon: self)

        // Hook up nexts
        //
        bridgePair.next = vertices[0].outEdge
        edges[vertices[0].outEdge].prev = bridgePair.id

        edges[vertices[start].outEdge].prev = bridge.id;
        bridge.next = vertices[start].outEdge;

        // hook up prevs
        //
        bridge.prev = edges[vertices[0].outEdge].pair;
        edges[edges[vertices[0].outEdge].pair].next = bridge.id

        bridgePair.prev = edges[vertices[start].outEdge].pair
        edges[edges[vertices[start].outEdge].pair].next = bridgePair.id
        vertices[start].outEdge = bridgePair.id

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

    mutating func flipOutEdges() {
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
        let eId = edges.count

        let e1 = Edge(id: eId, pairId: eId + 1, origin: v1.id)
        let e2 = Edge(id: eId + 1, pairId: eId, origin: v2.id)
        edges.append(e1)
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
