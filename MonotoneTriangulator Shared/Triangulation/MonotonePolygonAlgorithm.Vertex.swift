//
//  Vertex.swift
//  TriExploration
//
//  Created by Carl Wieland on 10/11/16.
//  Copyright © 2016 Datum Apps. All rights reserved.
//

import Foundation

extension MonotonePolygonAlgorithm {
    enum EventType {
        case start
        case end
        case split
        case merge
        case regular
    }

    class Vertex {

        init(point: Vector2) {
            self.x = point.x
            self.y = point.y
        }

        let x: Double
        let y: Double

        unowned var outEdge: Edge!

        var isMergeVertex = false

        private func turnAngle(a: Vertex, center b: Vertex, end c: Vertex) -> Double {
            let d1x = b.x - a.x;
            let d1y = b.y - a.y;

            let d2x = c.x - b.x;
            let d2y = c.y - b.y;

            var d2Ang = atan2(d2y,d2x);
            while d2Ang < 0  {
                d2Ang += .pi * 2
            }

            var d1Ang = atan2(d1y,d1x);
            while d1Ang < 0 {
                d1Ang += .pi * 2
            }

            var angle = d2Ang - d1Ang;
            if angle < 0 {
                angle += .pi * 2
            }

            return angle;
        }

        func generateEvent() -> EventType {
            let prev = self.outEdge.pair.next.pair.start;
            let next = self.outEdge.end

            let interiorAngle  = self.turnAngle(a:prev, center:self, end:next)
            if prev > self && next > self {
                if interiorAngle < .pi {
                    return .start;
                }
                else if interiorAngle > .pi {
                    return .split;
                }

            } else if self > next && self > prev {
                if interiorAngle < .pi {
                    return .end;
                }
                else if interiorAngle > .pi {
                    isMergeVertex = true
                    return .merge;
                }

            }
            return .regular;
        }

        func connectNew(edge: Edge) {
            guard var runner = self.outEdge else {
                fatalError("Invalid State!")
            }

            while runner.radAngle > edge.radAngle {
                runner = runner.pair.next;
                if runner.radAngle < runner.pair.next.radAngle || runner === runner.pair.next {
                    break;
                }
            }

            while (runner.radAngle < edge.radAngle) {
                runner = runner.prev.pair;
                if((runner.radAngle < edge.radAngle && runner.prev.pair.radAngle < runner.radAngle) || runner === runner.prev.pair){
                    runner = runner.prev.pair;
                    break;//we just went all the way around!
                }
            }
            //we found the insert location!
            runner.pair.next.prev = edge.pair;
            edge.pair.next = runner.pair.next;

            runner.pair.next = edge;
            runner.pair.next = edge;

            edge.prev = runner.pair;

        }

    }
}

extension MonotonePolygonAlgorithm.Vertex: CustomStringConvertible {
    var description: String {
        return "(\(x), \(y))"
    }
}

extension MonotonePolygonAlgorithm.Vertex: Hashable {
    func hash(into hasher: inout Hasher) {
        x.hash(into: &hasher)
        y.hash(into: &hasher)

    }
}

extension MonotonePolygonAlgorithm.Vertex: Comparable {

    public static func ==(lhs: MonotonePolygonAlgorithm.Vertex, rhs: MonotonePolygonAlgorithm.Vertex) -> Bool {
//        guard lhs !== rhs else {
//            return true
//        }
        let yDif = lhs.y - rhs.y
        let xDif = lhs.x - rhs.x
        return (yDif > -1e-6 && yDif < 1e-6) && ( xDif > -1e-6 && xDif < 1e-6)
    }

    public static func <(lhs: MonotonePolygonAlgorithm.Vertex, rhs: MonotonePolygonAlgorithm.Vertex) -> Bool {
        let yDif = lhs.y - rhs.y
        let xDif = lhs.x - rhs.x

        if (yDif > -1e-6 && yDif < 1e-6) {
            if xDif > -1e-6 && xDif < 1e-6 {
                return false
            }
            return lhs.x < rhs.x
        }
        return lhs.y > rhs.y

    }
}
