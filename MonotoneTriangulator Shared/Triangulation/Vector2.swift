//
//  Vector2.swift
//  TriExploration
//
//  Created by Carl Wieland on 10/11/16.
//  Copyright © 2016 Datum Apps. All rights reserved.
//

import Foundation
#if os(iOS)
import CoreGraphics
#endif
struct Vector2 {
    let x: Double
    let y: Double
    init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    init(_ position: CGPoint) {
        x = Double(position.x)
        y = Double(position.y)
    }

    var cgPoint: CGPoint {
        return CGPoint(x: x, y: y)
    }
}
