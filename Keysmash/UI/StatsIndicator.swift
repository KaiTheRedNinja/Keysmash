//
//  StatsIndicator.swift
//  Keysmash
//
//  Created by Kai Quan Tay on 24/10/26.
//

import SwiftUI
import Collections

struct StatsIndicator: View {
    var stats: GameStats

    @State var items: OrderedDictionary<UUID, StatItem> = [:]

    enum StatItem {
        case boatEaten
        case boatLost
        case rockEaten
        case rockAvoided
    }

    var body: some View {
        VStack {
            ForEach(items.elements, id: \.key) { (_, stat) in
                HStack {
                    switch stat {
                    case .boatEaten:
                        Text("+").font(.system(size: 50)).foregroundStyle(Color.green)
                        BoatView(
                            boat: .init(
                                coordinate: .zero,
                                angle: .zero,
                                velocity: .zero
                            )
                        )
                    case .boatLost:
                        Text("-").font(.system(size: 50)).foregroundStyle(Color.red)
                        BoatView(
                            boat: .init(
                                coordinate: .zero,
                                angle: .zero,
                                velocity: .zero
                            )
                        )
                    case .rockEaten:
                        Text("❌").font(.system(size: 50))
                        RockView(
                            rock: .init(
                                coordinate: .zero,
                                angle: .zero,
                                velocity: .zero,
                                sideCount: 9
                            )
                        )
                    case .rockAvoided:
                        Text("✅").font(.system(size: 50))
                        RockView(
                            rock: .init(
                                coordinate: .zero,
                                angle: .zero,
                                velocity: .zero,
                                sideCount: 9
                            )
                        )
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .onChange(of: stats) { oldValue, newValue in
            if newValue.boatsEaten > oldValue.boatsEaten {
                createThenDelete(stat: .boatEaten)
            }
            if newValue.boatsLost > oldValue.boatsLost {
                createThenDelete(stat: .boatLost)
            }
            if newValue.rocksEaten > oldValue.rocksEaten {
                createThenDelete(stat: .rockEaten)
            }
            if newValue.rocksAvoided > oldValue.rocksAvoided {
                createThenDelete(stat: .rockAvoided)
            }
        }
    }

    func createThenDelete(stat: StatItem) {
        let id = UUID()
        withAnimation {
            items[id] = stat
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                items[id] = nil
            }
        }
    }
}
