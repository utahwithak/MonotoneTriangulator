//
//  PolygonPartitioner.swift
//  TriExploration
//
//  Created by Carl Wieland on 10/11/16.
//  Copyright © 2016 Datum Apps. All rights reserved.
//

import Foundation

class PolygonPartitioner {

    private let polygon: Polygon
    private var queue: [MonotonePolygonAlgorithm.Vertex]
    private var helperMap = [Edge: MonotonePolygonAlgorithm.Vertex]()


    init(polygon: Polygon) {
        self.polygon = polygon
        queue = polygon.eventPoints
        queue.sort(by: >)
    }

    func sweep() throws {
        
        while !queue.isEmpty {
            let v = queue.removeLast()
            switch v.event {
            case .Start:
                handleStart(vertex: v)
            case .End:
                handleEnd(vertex: v)
            case .Split:
                try handleSplit(vertex: v)
            case .Merge:
                try handleMerge(vertex: v)
            case .Regular:
                try handleRegular(vertex: v)
            }
        }
    }

    var monotonePolygons: [SubPolygon] {
        return polygon.subPolygons
    }

    private func handleStart(vertex v:MonotonePolygonAlgorithm.Vertex) {
        set(helper: v, for: v.outEdge)
    }

    private func handleEnd(vertex v:MonotonePolygonAlgorithm.Vertex) {
        let helper = helperFor(edge:v.outEdge.pair.next.pair)
        if helper.event == .Merge {
            polygon.addDiagonalFrom(start:v, toVertex:helper)
        }
        remove(edge: v.outEdge.pair.next.pair)
    }

    private func handleSplit(vertex v:MonotonePolygonAlgorithm.Vertex) throws {
        let ej = try edgeOnLeft(of: v)
        polygon.addDiagonalFrom(start: v, toVertex: helperFor(edge: ej))
        set(helper: v, for: ej)
        set(helper: v, for: v.outEdge)
    }

    private func handleMerge(vertex v:MonotonePolygonAlgorithm.Vertex) throws {

        var helper = helperFor(edge: v.outEdge.pair.next.pair)
        if helper.event == .Merge {
            polygon.addDiagonalFrom(start:v, toVertex:helper)
        }
        remove(edge:v.outEdge.pair.next.pair)

        let ej = try edgeOnLeft(of: v)
        helper = helperFor(edge:ej)
        if helper.event == .Merge {
            polygon.addDiagonalFrom(start:v, toVertex:helper)
        }
        set(helper: v, for: ej)
    }

    private func handleLeftSide(vertex v: MonotonePolygonAlgorithm.Vertex) {
        let helper = helperFor(edge: v.outEdge.pair.next.pair)
        if helper.event == .Merge {
            polygon.addDiagonalFrom(start:v, toVertex:helper)
        }
        remove(edge: v.outEdge.pair.next.pair)
        set(helper: v, for: v.outEdge)
    }

    private func handleRightSide(vertex v: MonotonePolygonAlgorithm.Vertex) throws {
        let ej = try edgeOnLeft(of: v)
        let leftHelper = helperFor(edge: ej)
        if leftHelper.event == .Merge {
            polygon.addDiagonalFrom(start: v, toVertex:leftHelper)
        }
        set(helper: v, for: ej)
    }

    private func handleRegular(vertex v: MonotonePolygonAlgorithm.Vertex) throws {
        if v > v.outEdge.pair.next.pair.start {
            handleLeftSide(vertex:v)
        } else {
            try handleRightSide(vertex: v)
        }
    }

    private func set(helper: MonotonePolygonAlgorithm.Vertex, for edge: Edge) {
        helperMap[edge] = helper
    }

    private func helperFor(edge: Edge) -> MonotonePolygonAlgorithm.Vertex {
        return helperMap[edge]!
    }

    private func remove(edge: Edge) {
        helperMap.removeValue(forKey: edge)
    }

    private func edgeOnLeft(of v: MonotonePolygonAlgorithm.Vertex) throws -> Edge {
        let edgesAtY = helperMap.keys.filter {
            return $0.intersectsLine(at: v.y) && $0.leftIntersectionOfLine(at: v.y) < v.x
        }

        let sorted = edgesAtY.sorted { edge1, edge2 in
            return edge1.leftIntersectionOfLine(at: v.y) < edge2.leftIntersectionOfLine(at: v.y)
        }

        guard let last = sorted.last else {
            throw TriangulationError.InvalidPolygon
        }
        return last
    }
}
