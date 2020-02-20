//
//  Edge.swift
//  TriExploration
//
//  Created by Carl Wieland on 10/11/16.
//  Copyright © 2016 Datum Apps. All rights reserved.
//

import Foundation

class Edge {
    var next: Edge!
    var prev: Edge!
    var pair: Edge!
    let start: MonotonePolygonAlgorithm.Vertex

    init(origin: MonotonePolygonAlgorithm.Vertex) {
        self.start = origin
    }

    var end: MonotonePolygonAlgorithm.Vertex {
        return pair.start
    }

    lazy var radAngle: Double = {
        var dy = self.end.y - self.start.y;
        var dx = self.end.x - self.start.x;
        if dx < 1e-7 && dx > -1e-7 {
            dx = 0
        }
        if dy < 1e-7 && dy > -1e-7 {
            dy = 0
        }
        let radians = atan2(dy, dx);
        return radians
    }()

    lazy var degreeAngle: Double = {
        var degrees = self.radAngle * 180.0 / .pi;
        if degrees < 0 {
            degrees += 360
        }
        return degrees

    }()

    func pairWith(edge: Edge) {
        self.pair = edge;
        edge.pair = self
    }

    func intersectsLine(at lineY: Double) -> Bool {
        return (self.start.y >= lineY && self.end.y <= lineY) || (self.start.y <= lineY && self.end.y >= lineY);
    }

    func leftIntersectionOfLine(at lineY: Double) -> Double {
        precondition(intersectsLine(at: lineY))

        if self.start.y == lineY {
            if self.end.y == lineY && self.end.x < self.start.x {
                return self.end.x;
            } else {
                return self.start.x;
            }
        }
        if self.end.y == lineY {
            return self.end.x;
        }

        let val = self.start.x + (((self.end.x - self.start.x) / (self.end.y - self.start.y) * (lineY - self.start.y)));

        return val;
    }
}

extension Edge: CustomStringConvertible {

    var description: String {
        return "\(start) -> \(end)"
    }
}

extension Edge: Equatable {
    static func ==(lhs: Edge, rhs: Edge) -> Bool {

        guard lhs !== rhs else {
            return true
        }

        return lhs.start == rhs.start && lhs.end == rhs.end
    }
}

extension Edge: Hashable {
    func hash(into hasher: inout Hasher) {
        start.hash(into: &hasher)
        end.hash(into: &hasher)
    }
    
}
