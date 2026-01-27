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

    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text(title)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

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
            .frame(height: 180)
            .clipped()

            // Stats
            VStack(spacing: 0) {
                if let rating {
                    StatRow(label: "Rating", value: String(format: "%.1f", rating))
                }
                if let numberOfRatings {
                    StatRow(label: "Reviews", value: "\(numberOfRatings)")
                }
                if let totalTime {
                    StatRow(label: "Time", value: formatTime(totalTime))
                }
                if let calories {
                    StatRow(label: "Calories", value: calories)
                }
                if let carbs {
                    StatRow(label: "Carbs", value: carbs)
                }
                if let fat {
                    StatRow(label: "Fat", value: fat)
                }
                if let protein {
                    StatRow(label: "Protein", value: protein)
                }
            }
            .padding(.vertical, 4)
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

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
