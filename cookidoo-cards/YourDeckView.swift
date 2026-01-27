//
//  YourDeckView.swift
//  cookidoo-cards
//
//  Created by David Ochmann on 27.01.26.
//

import SwiftUI
import SwiftData

struct YourDeckView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedRecipe.savedAt, order: .reverse) private var savedRecipes: [SavedRecipe]
    @State private var showingSearch = false

    var body: some View {
        NavigationStack {
            Group {
                if savedRecipes.isEmpty {
                    ContentUnavailableView("No Saved Recipes", systemImage: "rectangle.on.rectangle.angled", description: Text("Tap + to search and add recipes."))
                } else {
                    ScrollView {
                        
                        
                        LazyVStack(spacing: 16) {
                            ForEach(savedRecipes) { saved in
                                RecipeCardView(
                                    title: saved.title,
                                    imageURL: saved.resolvedImageURL,
                                    rating: saved.rating,
                                    numberOfRatings: saved.numberOfRatings,
                                    totalTime: saved.totalTime,
                                    calories: saved.calories,
                                    carbs: saved.carbs,
                                    fat: saved.fat,
                                    protein: saved.protein
                                )
                                .contextMenu {
                                    Button(role: .destructive) {
                                        modelContext.delete(saved)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Your Deck")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSearch = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                NavigationLink {
                    GameView()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.accentColor, in: Circle())
                        .shadow(radius: 4, y: 2)
                }
                .padding(24)
                .opacity(savedRecipes.count < 2 ? 0.4 : 1.0)
                .disabled(savedRecipes.count < 2)
            }
            .sheet(isPresented: $showingSearch) {
                RecipeListView()
            }
        }
    }
}

#Preview {
    YourDeckView()
        .modelContainer(for: SavedRecipe.self, inMemory: true)
}
