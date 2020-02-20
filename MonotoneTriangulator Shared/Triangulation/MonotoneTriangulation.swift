//
//  MonotoneTriangulation.swift
//  TriExploration
//
//  Created by Carl Wieland on 10/11/16.
//  Copyright © 2016 Datum Apps. All rights reserved.
//

import Foundation

class MonotonePolygonAlgorithm {

    let polygon: Polygon

    init(points: [Vector2]) {
        polygon = Polygon(points: points)
    }

    func triangulate() throws -> [Int] {
        var partitioner = PolygonPartitioner(polygon: polygon)

        try partitioner.sweep()

        let subPolygons = partitioner.monotonePolygons
        var sequence = [MonotonePolygonAlgorithm.Vertex]()
        var leftChain = [MonotonePolygonAlgorithm.Vertex]()
        var rightChain = [MonotonePolygonAlgorithm.Vertex]()
        var stack = [MonotonePolygonAlgorithm.Vertex]()
        
        for p in subPolygons {
            sequenceStarting(at: p.startEdge, sequence: &sequence)
            guard let lowest = p.edgeStarting(at: sequence.last!), let highest = p.edgeStarting(at: sequence.first!) else {
                fatalError("Start not on list!")
            }

            var runner = highest
            repeat {
                runner = runner.prev
                rightChain.append(runner.start)
            } while runner !== lowest;

            runner = highest

            repeat {
                leftChain.append(runner.start)
                runner = runner.next
            } while runner !== lowest

            stack.append(sequence[0])
            stack.append(sequence[1])
            for i in 2..<(sequence.count - 1) {
                let u = sequence[i]

                if (leftChain.contains(u) && !leftChain.contains(stack.last!)) || (rightChain.contains(u) && !rightChain.contains(stack.last!)){
                    while stack.count != 0 {
                        let cur = stack.removeLast()

                        //inserte into D a diagonal from U to each popped vertex, except the last one
                        if stack.count > 0 {
                            polygon.addDiagonalFrom(start:u, toVertex:cur)
                        }
                    }

                    //push u-1 and u onto stack
                    stack.append(sequence[i-1])
                    stack.append(u)

                }
                else{
                    //Pop One vertext from S
                    var popped = stack.removeLast()


                    //pop the other vertices from S as long as the diagonals from u to them are inside P
                    while stack.count > 0 && sideOfPoints(a:stack.last!, center:popped, andEnd:u) == (leftChain.contains(u) ? 1 : -1)  {

                        popped = stack.removeLast()

                        polygon.addDiagonalFrom(start:u, toVertex:popped)
                    }
                    //push last popped back onto stack, as it is now (or always was) connected to
                    stack.append(popped)
                    stack.append(u)

                }

            }
            if stack.count > 0 {
                _ = stack.removeLast()

                while stack.count != 0 {
                    let cur = stack.removeLast()
                    //insert into D a diagonal from U to each poped vertex, except the last one
                    if stack.count > 0 {
                        polygon.addDiagonalFrom(start:sequence.last!, toVertex:cur)
                    }
                }


            }


            stack.removeAll(keepingCapacity: true)
            rightChain.removeAll(keepingCapacity: true)
            leftChain.removeAll(keepingCapacity: true)
            sequence.removeAll(keepingCapacity: true)
        }

        return polygon.triangles
    }


    private func sideOfPoints(a:Vertex, center b:Vertex, andEnd c:Vertex) -> Int {
        let v1x = b.x-a.x;
        let v1y = b.y-a.y;

        let v2x = c.x-b.x;
        let v2y = c.y-b.y;

        return (v1x * v2y) - (v1y * v2x) < 0 ? -1 : 1
    }
    func sequenceStarting(at startEdge: Edge, sequence: inout [Vertex]) {

        var runner = startEdge
        repeat {
            sequence.append(runner.start)
            runner = runner.next;
        }while(runner != startEdge);

        sequence.sort()

    }
}

enum TriangulationError: Error {
case InvalidPolygon
}
