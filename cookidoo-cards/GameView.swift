//
//  GameView.swift
//  cookidoo-cards
//
//  Created by David Ochmann on 27.01.26.
//

import SwiftUI

struct GameView: View {
    var body: some View {
        ContentUnavailableView("Coming Soon", systemImage: "gamecontroller", description: Text("The game mode is not yet available."))
            .navigationTitle("Game")
    }
}

#Preview {
    NavigationStack {
        GameView()
    }
}
