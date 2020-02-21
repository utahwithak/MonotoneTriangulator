//
//  PolygonPartitioner.swift
//  TriExploration
//
//  Created by Carl Wieland on 10/11/16.
//  Copyright © 2016 Datum Apps. All rights reserved.
//

import Foundation

struct PolygonPartitioner {

    private var helperMap = [Edge: MonotonePolygonAlgorithm.Vertex]()

    mutating func sweep(polygon: Polygon) throws -> [SubPolygon] {
        let queue = polygon.vertices.sorted(by: >)
        for i in stride(from: queue.count - 1, through: 0, by: -1) {
            let v = queue[i]
            switch v.generateEvent() {
            case .Start:
                handleStart(vertex: v)
            case .End:
                try handleEnd(vertex: v)
            case .Split:
                try handleSplit(vertex: v)
            case .Merge:
                try handleMerge(vertex: v)
            case .Regular:
                try handleRegular(vertex: v)
            }
        }
        return polygon.subPolygons
    }

    private mutating func handleStart(vertex v:MonotonePolygonAlgorithm.Vertex) {
        set(helper: v, for: v.outEdge)
    }

    private mutating func handleEnd(vertex v:MonotonePolygonAlgorithm.Vertex) throws {
        let helper = try helperFor(edge:v.outEdge.pair.next.pair)
        if helper.isMergeVertex {
            Polygon.addDiagonalFrom(start:v, toVertex:helper)
        }
        remove(edge: v.outEdge.pair.next.pair)
    }

    private mutating func handleSplit(vertex v:MonotonePolygonAlgorithm.Vertex) throws {
        let ej = try edgeOnLeft(of: v)
        Polygon.addDiagonalFrom(start: v, toVertex: try helperFor(edge: ej))
        set(helper: v, for: ej)
        set(helper: v, for: v.outEdge)
    }

    private mutating func handleMerge(vertex v:MonotonePolygonAlgorithm.Vertex) throws {

        var helper = try helperFor(edge: v.outEdge.pair.next.pair)
        if helper.isMergeVertex {
            Polygon.addDiagonalFrom(start:v, toVertex:helper)
        }
        remove(edge:v.outEdge.pair.next.pair)

        let ej = try edgeOnLeft(of: v)
        helper = try helperFor(edge:ej)
        if helper.isMergeVertex {
            Polygon.addDiagonalFrom(start:v, toVertex:helper)
        }
        set(helper: v, for: ej)
    }

    private mutating func handleLeftSide(vertex v: MonotonePolygonAlgorithm.Vertex) throws {
        let helper = try helperFor(edge: v.outEdge.pair.next.pair)
        if helper.isMergeVertex {
            Polygon.addDiagonalFrom(start:v, toVertex:helper)
        }
        remove(edge: v.outEdge.pair.next.pair)
        set(helper: v, for: v.outEdge)
    }

    private mutating func handleRightSide(vertex v: MonotonePolygonAlgorithm.Vertex) throws {
        let ej = try edgeOnLeft(of: v)
        let leftHelper = try helperFor(edge: ej)
        if leftHelper.isMergeVertex {
            Polygon.addDiagonalFrom(start: v, toVertex:leftHelper)
        }
        set(helper: v, for: ej)
    }

    private mutating func handleRegular(vertex v: MonotonePolygonAlgorithm.Vertex) throws {
        if v > v.outEdge.pair.next.pair.start {
            try handleLeftSide(vertex:v)
        } else {
            try handleRightSide(vertex: v)
        }
    }

    private mutating func set(helper: MonotonePolygonAlgorithm.Vertex, for edge: Edge) {
        helperMap[edge] = helper
    }

    private func helperFor(edge: Edge) throws -> MonotonePolygonAlgorithm.Vertex {
        guard let edge =  helperMap[edge] else {
            throw TriangulationError.InvalidPolygon
        }
        return edge
    }

    private mutating func remove(edge: Edge) {
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
