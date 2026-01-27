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
                    List {
                        ForEach(savedRecipes) { saved in
                            SavedRecipeRow(saved: saved)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        modelContext.delete(saved)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
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
            .sheet(isPresented: $showingSearch) {
                RecipeListView()
            }
        }
    }
}

struct SavedRecipeRow: View {
    let saved: SavedRecipe

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .foregroundStyle(.quaternary)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(saved.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    if let rating = saved.rating, rating > 0 {
                        Label(String(format: "%.1f", rating), systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    if let totalTime = saved.totalTime, totalTime > 0 {
                        Label(formatTime(totalTime), systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let count = saved.numberOfRatings, count > 0 {
                        Text("\(count) ratings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    if let cal = saved.calories {
                        NutritionBadge(label: "Cal", value: cal)
                    }
                    if let carbs = saved.carbs {
                        NutritionBadge(label: "Carbs", value: carbs)
                    }
                    if let fat = saved.fat {
                        NutritionBadge(label: "Fat", value: fat)
                    }
                    if let protein = saved.protein {
                        NutritionBadge(label: "Protein", value: protein)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var imageURL: URL? {
        guard let raw = saved.imageURL else { return nil }
        let resolved = raw.replacingOccurrences(of: "{transformation}", with: "t_mob80x80%402x")
        return URL(string: resolved)
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remaining = minutes % 60
            return remaining > 0 ? "\(hours)h \(remaining)min" : "\(hours)h"
        }
        return "\(minutes) min"
    }
}

#Preview {
    YourDeckView()
        .modelContainer(for: SavedRecipe.self, inMemory: true)
}
