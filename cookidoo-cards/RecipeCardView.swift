//
//  RecipeCardView.swift
//  cookidoo-cards
//
//  Created by David Ochmann on 27.01.26.
//

import SwiftUI

private struct StatTapActionKey: EnvironmentKey {
    static let defaultValue: ((String) -> Void)? = nil
}

extension EnvironmentValues {
    var onStatTapped: ((String) -> Void)? {
        get { self[StatTapActionKey.self] }
        set { self[StatTapActionKey.self] = newValue }
    }
}

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

    @Environment(\.onStatTapped) private var onStatTapped

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
                    statRow(label: "Rating", value: String(format: "%.1f", rating), key: "rating")
                }
                if let numberOfRatings {
                    statRow(label: "Reviews", value: "\(numberOfRatings)", key: "reviews")
                }
                if let totalTime {
                    statRow(label: "Time", value: formatTime(totalTime), key: "time")
                }
                if let calories {
                    statRow(label: "Calories", value: calories, key: "calories")
                }
                if let carbs {
                    statRow(label: "Carbs", value: carbs, key: "carbs")
                }
                if let fat {
                    statRow(label: "Fat", value: fat, key: "fat")
                }
                if let protein {
                    statRow(label: "Protein", value: protein, key: "protein")
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

    @ViewBuilder
    private func statRow(label: String, value: String, key: String) -> some View {
        let row = StatRow(label: label, value: value, isHighlighted: highlightedStat == key)

        if let onStatTapped {
            Button { onStatTapped(key) } label: { row }
                .buttonStyle(.plain)
        } else {
            row
        }
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
    var isHighlighted: Bool = false

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
        .background(isHighlighted ? Color.accentColor.opacity(0.15) : Color.clear)
    }
}
