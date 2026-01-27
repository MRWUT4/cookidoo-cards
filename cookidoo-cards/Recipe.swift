//
//  Recipe.swift
//  cookidoo-cards
//
//  Created by David Ochmann on 27.01.26.
//

import Foundation
import SwiftData

struct RecipeSearchResponse: Codable {
    let data: [Recipe]
}

struct Recipe: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let rating: Double?
    let numberOfRatings: Int?
    let publishedAt: String?
    let image: String?
    let totalTime: Int?
    let objectID: String?
    let descriptiveAssets: [DescriptiveAsset]?
}

struct DescriptiveAsset: Codable, Equatable {
    let square: String?
}

struct NutritionInfo: Codable, Equatable {
    let calories: String?
    let carbohydrateContent: String?
    let fatContent: String?
    let proteinContent: String?
}

struct RecipeJsonLd: Codable {
    let nutrition: NutritionInfo?
}

@Model
final class SavedRecipe {
    @Attribute(.unique) var recipeId: String
    var title: String
    var rating: Double?
    var numberOfRatings: Int?
    var totalTime: Int?
    var imageURL: String?
    var calories: String?
    var carbs: String?
    var fat: String?
    var protein: String?
    var savedAt: Date

    init(recipe: Recipe, nutrition: NutritionInfo? = nil) {
        self.recipeId = recipe.id
        self.title = recipe.title
        self.rating = recipe.rating
        self.numberOfRatings = recipe.numberOfRatings
        self.totalTime = recipe.totalTime
        self.imageURL = recipe.descriptiveAssets?.first?.square ?? recipe.image
        self.calories = nutrition?.calories
        self.carbs = nutrition?.carbohydrateContent
        self.fat = nutrition?.fatContent
        self.protein = nutrition?.proteinContent
        self.savedAt = Date()
    }
}
