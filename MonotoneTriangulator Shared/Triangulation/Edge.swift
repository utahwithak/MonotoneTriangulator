//
//  Edge.swift
//  TriExploration
//
//  Created by Carl Wieland on 10/11/16.
//  Copyright © 2016 Datum Apps. All rights reserved.
//

import Foundation

class Edge {
    var next: Int = -1
    var prev: Int = -1
    var pair: Int = -1

    let start: Int

    let id: Int

    init(id: Int, origin: Int) {
        self.id = id
        self.start = origin
    }

    var radAngle: Double = 0

    func pairWith(edge: Edge, polygon: Polygon) {
        self.pair = edge.id;
        edge.pair = self.id
        let end = polygon.vertices[edge.start]
        let start = polygon.vertices[self.start]
        let dy = end.y - start.y;
        let dx = end.x - start.x;

        radAngle = atan2(dy, dx);
        if radAngle < 0 {
             radAngle += .pi * 2
        }

        edge.radAngle = radAngle - .pi
        if edge.radAngle < 0 {
            edge.radAngle += .pi * 2
        }

    }

    func intersectsLine(at lineY: Double, polygon: Polygon) -> Bool {
        let start = polygon.vertices[self.start]
        let end = polygon.vertices[polygon.edges[pair].start]
        return (start.y >= lineY && end.y <= lineY) || (start.y <= lineY && end.y >= lineY);
    }

    func leftIntersectionOfLine(at lineY: Double, polygon: Polygon) -> Double {

        let start = polygon.vertices[self.start]
        let end = polygon.vertices[polygon.edges[pair].start]
        if start.y == lineY {
            if end.y == lineY && end.x < start.x {
                return end.x;
            } else {
                return start.x;
            }
        }
        if end.y == lineY {
            return end.x;
        }

        let val = start.x + (((end.x - start.x) / (end.y - start.y) * (lineY - start.y)));

        return val;
    }
}

extension Edge: Equatable {
    static func ==(lhs: Edge, rhs: Edge) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Edge: Hashable {
    func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
}
