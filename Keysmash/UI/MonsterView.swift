//
//  MonsterView.swift
//  Keysmash
//
//  Created by Kai Quan Tay on 21/10/26.
//

import SwiftUI

struct MonsterView: View {
    var body: some View {
        Rectangle()
            .frame(width: monsterWidth, height: segmentSeaLevel)
    }
}

#Preview {
    ZStack(alignment: .top) {
        MonsterView()
            .border(Color.red, width: 1)
    }
    .padding(50)
}
