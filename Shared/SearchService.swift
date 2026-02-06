//
//  SearchService.swift
//  cookidoo-cards
//
//  Created by David Ochmann on 27.01.26.
//

import Foundation

@Observable
class SearchService {
    var recipes: [Recipe] = []
    var isLoading = false
    var errorMessage: String?

    private let baseURL = "https://de.web.production-eu.cookidoo.vorwerk-digital.com/search/api/de/search"

    func search(query: String, limit: Int = 20) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "limit", value: String(limit)),
        ]

        guard let url = components.url else {
            errorMessage = "Invalid URL"
            return
        }

        let request = URLRequest(url: url)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Invalid response"
                return
            }

            guard httpResponse.statusCode == 200 else {
                errorMessage = "Search failed (HTTP \(httpResponse.statusCode))"
                return
            }

            let result = try JSONDecoder().decode(RecipeSearchResponse.self, from: data)
            recipes = result.data
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }
    }
}
