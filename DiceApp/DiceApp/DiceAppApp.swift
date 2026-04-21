//
//  DiceAppApp.swift
//  DiceApp
//
//  Created by Riolu on 4/10/26.
//

import SwiftUI

@Observable
class DiceDate {
    var rolledNumber = 0
    
}

@main
struct DiceAppApp: App {
    @State var diceData = DiceDate()
    
    var body: some Scene {
        //MARK: 두개의 분리된 Scene이 있다
        
        //하나는 윈도우
        WindowGroup {
            ContentView(diceData: diceData)
        }
        .defaultSize(width: 100, height: 100)
        
        WindowGroup {
            DicePanelView(diceData: diceData)
        }
        .defaultSize(width: 100, height: 100)
        
        //하나는 dice가 표시되는 몰입형 공간
        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView(diceData: diceData)
        }
        
    }
}
