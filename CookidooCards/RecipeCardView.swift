//
//  RecipeCardView.swift
//  cookidoo-cards
//
//  Created by David Ochmann on 27.01.26.
//

import SwiftUI

struct RecipeCardView: View {
    let title: String
    let imageURL: URL?
    let rating: Double?
    let numberOfRatings: Int?
    let totalTime: Int?
    let calories: String?
    let carbs: String?
    let fat: String?
    let protein: String?

    var highlightedStat: String? = nil
    var redactStats: Bool = false
    var scale: CGFloat = 1.0

    private var statItems: [(label: String, value: String, key: String)] {
        var items: [(String, String, String)] = []
        if let rating { items.append(("Rating", String(format: "%.1f", rating), "rating")) }
        if let numberOfRatings { items.append(("Reviews", "\(numberOfRatings)", "reviews")) }
        if let totalTime { items.append(("Time", formatTime(totalTime), "time")) }
        if let calories { items.append(("Calories", calories, "calories")) }
        if let carbs { items.append(("Carbs", carbs, "carbs")) }
        if let fat { items.append(("Fat", fat, "fat")) }
        if let protein { items.append(("Protein", protein, "protein")) }
        return items
    }

    var body: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width / scale
            let cardHeight = geo.size.height / scale

            cardContent(cardHeight: cardHeight)
                .frame(width: cardWidth, height: cardHeight)
                .drawingGroup()
                .scaleEffect(scale)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(5.0 / 7.0, contentMode: .fit)
    }

    private func cardContent(cardHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Image
            AsyncImage(url: imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .foregroundStyle(.quaternary)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(height: cardHeight / 2)
            .clipped()

            // Title
            Text(title)
                .font(.title)
                .fontWeight(.semibold)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

            // Stats
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 0) {
                ForEach(statItems, id: \.key) { item in
                    StatRow(label: item.label, value: item.value, isHighlighted: highlightedStat == item.key)
                }
            }
            .padding(.vertical, 4)
            .redacted(reason: redactStats ? .placeholder : [])

            Spacer(minLength: 0)
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.separator, lineWidth: 1)
        )
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
    RecipeCardView(
        title: "Spaghetti Bolognese",
        imageURL: URL(string: "https://assets.tmecosys.com/image/upload/t_mob400x333%402x/img/recipe/ras/Assets/d2db89d7289e3a5794ff8b97dea812bf/Derivates/02983fa7c9a526b58094f08f91935100ea25c3ca"),
        rating: 4.3,
        numberOfRatings: 128,
        totalTime: 2400,
        calories: "350 kcal",
        carbs: "45 g",
        fat: "12 g",
        protein: "18 g",
        highlightedStat: "rating"
    )
    .padding()
}

private struct StatRow: View {
    let label: String
    let value: String
    var isHighlighted: Bool = false

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .background(isHighlighted ? Color.accentColor.opacity(0.15) : Color.clear)
    }
}
