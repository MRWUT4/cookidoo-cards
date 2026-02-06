//
//  RecipeDetailService.swift
//  cookidoo-cards
//
//  Created by David Ochmann on 27.01.26.
//

import Foundation

@Observable
class RecipeDetailService {
    var nutritionByRecipeId: [String: NutritionInfo] = [:]

    private let detailBaseURL = "https://de.web.production-eu.cookidoo.vorwerk-digital.com/recipes/recipe/de"

    func fetchNutrition(for recipes: [Recipe]) async {
        await withTaskGroup(of: (String, NutritionInfo?).self) { group in
            for recipe in recipes {
                guard nutritionByRecipeId[recipe.id] == nil else { continue }
                group.addTask {
                    let nutrition = await self.fetchNutrition(recipeId: recipe.id)
                    return (recipe.id, nutrition)
                }
            }

            for await (id, nutrition) in group {
                if let nutrition {
                    nutritionByRecipeId[id] = nutrition
                }
            }
        }
    }

    private func fetchNutrition(recipeId: String) async -> NutritionInfo? {
        guard let url = URL(string: "\(detailBaseURL)/\(recipeId)") else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let html = String(data: data, encoding: .utf8) else {
                return nil
            }

            return parseNutrition(from: html)
        } catch {
            return nil
        }
    }

    private func parseNutrition(from html: String) -> NutritionInfo? {
        guard let startRange = html.range(of: "<script type=\"application/ld+json\">"),
              let endRange = html.range(of: "</script>", range: startRange.upperBound..<html.endIndex) else {
            return nil
        }

        let jsonString = html[startRange.upperBound..<endRange.lowerBound]
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }

        let decoded = try? JSONDecoder().decode(RecipeJsonLd.self, from: jsonData)
        return decoded?.nutrition
    }
}
