//
//  cookidoo_cardsApp.swift
//  cookidoo-cards
//
//  Created by David Ochmann on 27.01.26.
//

import SwiftUI

@main
struct CookidooCards: App {
    @State private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authService)
        }
    }
}
