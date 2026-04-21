//
//  ContentView.swift
//  DiceApp
//
//  Created by Riolu on 4/10/26.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @Environment(\.openImmersiveSpace) var openImmersiveSpace

    var diceData : DiceDate

    var body: some View {
        VStack {

            Text(diceData.rolledNumber == 0 ? "🎲" : "\(diceData.rolledNumber)")
                .foregroundStyle(.yellow)
                .font(.custom("Menlo", size: 100))
                .bold()

        }
        .task { //이렇게하면 앱 실행하자마자 바로 몰입형 공간으로 열림
            await openImmersiveSpace(id: "ImmersiveSpace")
        }
    }
}

// MARK: - 주사위 위에 띄울 패널 뷰
struct DicePanelView: View {
    var diceData: DiceDate

    var body: some View {
        Text(diceData.rolledNumber == 0 ? "🎲" : "\(diceData.rolledNumber)")
            .foregroundStyle(.yellow)
            .font(.custom("Menlo", size: 60))
            .bold()
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .glassBackgroundEffect()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView(diceData: DiceDate())
    //        .environment(AppModel())
}
