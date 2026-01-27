//
//  RecipeListView.swift
//  cookidoo-cards
//
//  Created by David Ochmann on 27.01.26.
//

import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var searchService = SearchService()
    @State private var detailService = RecipeDetailService()
    @State private var query = ""

    private var canAdd: Bool {
        !searchService.recipes.isEmpty && !detailService.nutritionByRecipeId.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if searchService.isLoading {
                    ProgressView("Searching...")
                } else if let error = searchService.errorMessage {
                    ContentUnavailableView("Search Failed", systemImage: "exclamationmark.triangle", description: Text(error))
                } else if searchService.recipes.isEmpty {
                    ContentUnavailableView("No Recipes", systemImage: "magnifyingglass", description: Text("Search for recipes to get started."))
                } else {
                    List(searchService.recipes) { recipe in
                        RecipeRow(recipe: recipe, nutrition: detailService.nutritionByRecipeId[recipe.id])
                    }
                }
            }
            .navigationTitle("Cookidoo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        addRecipes()
                        dismiss()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(!canAdd)
                }
            }
            .searchable(text: $query, prompt: "Search recipes")
            .onSubmit(of: .search) {
                performSearch()
            }
            .task {
                performSearch()
            }
            .onChange(of: searchService.recipes) {
                Task {
                    await detailService.fetchNutrition(for: searchService.recipes)
                }
            }
        }
    }

    private func addRecipes() {
        for recipe in searchService.recipes {
            guard let nutrition = detailService.nutritionByRecipeId[recipe.id] else { continue }
            let saved = SavedRecipe(recipe: recipe, nutrition: nutrition)
            modelContext.insert(saved)
        }
    }

    private func performSearch() {
        let searchQuery = query.isEmpty ? "" : query
        Task {
            await searchService.search(query: searchQuery)
        }
    }
}

struct RecipeRow: View {
    let recipe: Recipe
    let nutrition: NutritionInfo?

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
                Text(recipe.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    if let rating = recipe.rating, rating > 0 {
                        Label(String(format: "%.1f", rating), systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    if let totalTime = recipe.totalTime, totalTime > 0 {
                        Label(formatTime(totalTime), systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let count = recipe.numberOfRatings, count > 0 {
                        Text("\(count) ratings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let nutrition {
                    HStack(spacing: 8) {
                        if let cal = nutrition.calories {
                            NutritionBadge(label: "Cal", value: cal)
                        }
                        if let carbs = nutrition.carbohydrateContent {
                            NutritionBadge(label: "Carbs", value: carbs)
                        }
                        if let fat = nutrition.fatContent {
                            NutritionBadge(label: "Fat", value: fat)
                        }
                        if let protein = nutrition.proteinContent {
                            NutritionBadge(label: "Protein", value: protein)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var imageURL: URL? {
        let raw = recipe.descriptiveAssets?.first?.square ?? recipe.image
        guard let raw else { return nil }
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

struct NutritionBadge: View {
    let label: String
    let value: String

    var body: some View {
        Text("\(label): \(value)")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
    }
}

#Preview {
    RecipeListView()
        .environment(AuthService())
}
