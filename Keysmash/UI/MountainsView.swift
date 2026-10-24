//
//  MountainsView.swift
//  Keysmash
//
//  Created by Kai Quan Tay on 24/10/26.
//

import SwiftUI

struct MountainsView: View {
    func noise(seed: CGFloat) -> CGFloat {
        sin(seed * 1234567890)
    }

    var body: some View {
        ZStack {
            Color(nsColor: NSColor(hue: 0.6, saturation: 0.5, brightness: 0.3, alpha: 1))

            mountain(
                baseXStart: 0.0,
                peakX: 0.45,
                peakY: 0.7,
                baseXEnd: 0.6,
                segments: 20,
                seed: 1
            )
            .fill(Color(nsColor: NSColor(hue: 0.6, saturation: 0.12, brightness: 0.6, alpha: 1)))

            mountain(
                baseXStart: 0.0,
                peakX: 0.7,
                peakY: 0.6,
                baseXEnd: 1,
                segments: 20,
                seed: 1
            )
            .fill(Color(nsColor: NSColor(hue: 0.6, saturation: 0.12, brightness: 0.6, alpha: 1)))

            mountain(
                baseXStart: 0.0,
                peakX: 0.3,
                peakY: 0.7,
                baseXEnd: 0.6,
                segments: 20,
                seed: 1
            )
            .fill(Color(nsColor: NSColor(hue: 0.6, saturation: 0.12, brightness: 0.5, alpha: 1)))

            mountain(
                baseXStart: 0.2,
                peakX: 0.6,
                peakY: 0.8,
                baseXEnd: 0.8,
                segments: 20,
                seed: 0
            )
            .fill(Color(nsColor: NSColor(hue: 0.6, saturation: 0.12, brightness: 0.4, alpha: 1)))

            mountain(
                baseXStart: 0.6,
                peakX: 0.9,
                peakY: 0.9,
                baseXEnd: 1.2,
                segments: 20,
                seed: 0
            )
            .fill(Color(nsColor: NSColor(hue: 0.6, saturation: 0.12, brightness: 0.3, alpha: 1)))

            mountain(
                baseXStart: -0.2,
                peakX: 0.1,
                peakY: 0.8,
                baseXEnd: 0.4,
                segments: 20,
                seed: 0
            )
            .fill(Color(nsColor: NSColor(hue: 0.6, saturation: 0.12, brightness: 0.25, alpha: 1)))
        }
        .scaleEffect(y: -1)
        .frame(width: screenSize.width, height: screenSize.height)
    }

    func mountain(
        baseXStart: CGFloat,
        peakX: CGFloat,
        peakY: CGFloat,
        baseXEnd: CGFloat,
        segments: Int,
        seed: CGFloat
    ) -> Path {
        Path { path in
            let noiseSize = 0.03 * screenSize.height

            // values
            let peakHeight = peakY * screenSize.height
            let startPoint = CGPoint(x: baseXStart * screenSize.width, y: 0)
            let peakPoint = CGPoint(x: peakX * screenSize.width, y: peakHeight)
            let endPoint = CGPoint(x: baseXEnd * screenSize.width, y: 0)

            // uphill climb
            path.move(to: startPoint)
            for index in 0...segments {
                let xVal = startPoint.x + CGFloat(index)/CGFloat(segments) * (peakPoint.x - startPoint.x)
                    + noiseSize * noise(seed: seed + CGFloat(index) + baseXStart)
                let yVal = CGFloat(index)/CGFloat(segments) * peakHeight
                    + noiseSize * noise(seed: seed + xVal)

                path.addLine(to: .init(x: xVal, y: yVal))
            }
            // downhill climb
            for index in 0...segments {
                let xVal = peakPoint.x + CGFloat(index)/CGFloat(segments) * (endPoint.x - peakPoint.x)
                    + noiseSize * noise(seed: seed + CGFloat(index) + baseXEnd)
                let yVal = peakHeight - CGFloat(index)/CGFloat(segments) * peakHeight
                    + noiseSize * noise(seed: seed + xVal + 1)

                path.addLine(to: .init(x: xVal, y: yVal))
            }
            // close the shape
            path.addLine(to: endPoint)
            path.addLine(to: startPoint)
            path.closeSubpath()
        }
    }
}

#Preview {
    MountainsView()
        .scaleEffect(1/4, anchor: .center)
        .frame(width: screenSize.width/4, height: screenSize.height/4)
}
