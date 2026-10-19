//
//  Bezier.swift
//  Keysmash
//
//  Created by Kai Quan Tay on 19/10/26.
//

import Foundation

struct Bezier {
    var start: CGPoint
    var segments: [BezierSegment]

    init(start: CGPoint, segments: [BezierSegment]) {
        self.start = start
        self.segments = segments
    }

    init?(points: [CGPoint]) {
        guard let first = points.first else { return nil }

        var segments: [BezierSegment] = []

        guard points.count > 1 else { return nil }

        // draw a smooth line
        for i in 0..<(points.count - 1) {
            let current = points[i]
            let next = points[i + 1]

            let previous = i > 0 ? points[i - 1] : current
            let following = i + 2 < points.count
            ? points[i + 2]
            : next

            let tension: CGFloat = 1.0 / 6.0

            let control1 = CGPoint(
                x: current.x + (next.x - previous.x) * tension,
                y: current.y + (next.y - previous.y) * tension
            )

            let control2 = CGPoint(
                x: next.x - (following.x - current.x) * tension,
                y: next.y - (following.y - current.y) * tension
            )

            segments.append(.init(control1: control1, control2: control2, end: next))
        }

        self.init(start: first, segments: segments)
    }
}

struct BezierSegment {
    var control1: CGPoint
    var control2: CGPoint
    var end: CGPoint
}

func bezierGradient(
    p0: CGPoint,
    c1: CGPoint,
    c2: CGPoint,
    p1: CGPoint,
    atX targetX: CGFloat
) -> CGFloat? {
    // Find t such that the Bézier curve's x coordinate
    // equals targetX. Binary search works when x(t) is monotonic.
    var low: CGFloat = 0
    var high: CGFloat = 1

    for _ in 0..<40 {
        let t = (low + high) / 2
        let u = 1 - t

        let x = u * u * u * p0.x
        + 3 * u * u * t * c1.x
        + 3 * u * t * t * c2.x
        + t * t * t * p1.x

        if x < targetX {
            low = t
        } else {
            high = t
        }
    }

    let t = (low + high) / 2
    let u = 1 - t

    let dx = 3 * u * u * (c1.x - p0.x)
    + 6 * u * t * (c2.x - c1.x)
    + 3 * t * t * (p1.x - c2.x)

    let dy = 3 * u * u * (c1.y - p0.y)
    + 6 * u * t * (c2.y - c1.y)
    + 3 * t * t * (p1.y - c2.y)

    guard abs(dx) > 1e-10 else {
        return nil
    }

    return dy / dx
}
