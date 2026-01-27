//
//  Recipe.swift
//  cookidoo-cards
//
//  Created by David Ochmann on 27.01.26.
//

import Foundation

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

struct NutritionInfo: Codable {
    let calories: String?
    let carbohydrateContent: String?
    let fatContent: String?
    let proteinContent: String?
}

struct RecipeJsonLd: Codable {
    let nutrition: NutritionInfo?
}
