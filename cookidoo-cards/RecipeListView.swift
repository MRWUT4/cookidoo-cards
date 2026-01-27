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
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(searchService.recipes) { recipe in
                                RecipeCardView(
                                    title: recipe.title,
                                    imageURL: recipeImageURL(recipe),
                                    rating: recipe.rating,
                                    numberOfRatings: recipe.numberOfRatings,
                                    totalTime: recipe.totalTime,
                                    calories: detailService.nutritionByRecipeId[recipe.id]?.calories,
                                    carbs: detailService.nutritionByRecipeId[recipe.id]?.carbohydrateContent,
                                    fat: detailService.nutritionByRecipeId[recipe.id]?.fatContent,
                                    protein: detailService.nutritionByRecipeId[recipe.id]?.proteinContent
                                )
                            }
                        }
                        .padding()
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

    private func recipeImageURL(_ recipe: Recipe) -> URL? {
        let raw = recipe.descriptiveAssets?.first?.square ?? recipe.image
        guard let raw else { return nil }
        let resolved = raw.replacingOccurrences(of: "{transformation}", with: "t_web750x500")
        return URL(string: resolved)
    }

    private func performSearch() {
        let searchQuery = query.isEmpty ? "" : query
        Task {
            await searchService.search(query: searchQuery)
        }
    }
}

#Preview {
    RecipeListView()
        .environment(AuthService())
}
