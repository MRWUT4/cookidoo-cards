//
//  ContentView.swift
//  cookidoo-cards
//
//  Created by David Ochmann on 27.01.26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        YourDeckView()
    }
}

#Preview {
    ContentView()
        .environment(AuthService())
}
