//
//  ContentView.swift
//  cookidoo-cards
//
//  Created by David Ochmann on 27.01.26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Recipes", systemImage: "fork.knife") {
                RecipeListView()
            }
            Tab("Account", systemImage: "person.crop.circle") {
                AuthenticationView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthService())
}
