//
//  GameView.swift
//  cookidoo-cards
//
//  Created by David Ochmann on 27.01.26.
//

import SwiftUI
import SwiftData

enum GameStat: String, CaseIterable {
    case rating, reviews, time, calories, carbs, fat, protein

    var label: String {
        switch self {
        case .rating: "Rating"
        case .reviews: "Reviews"
        case .time: "Time"
        case .calories: "Calories"
        case .carbs: "Carbs"
        case .fat: "Fat"
        case .protein: "Protein"
        }
    }

    func value(for recipe: SavedRecipe) -> Double? {
        switch self {
        case .rating:
            recipe.rating
        case .reviews:
            recipe.numberOfRatings.map { Double($0) }
        case .time:
            recipe.totalTime.map { Double($0) }
        case .calories:
            recipe.calories.flatMap { Self.parseNumeric($0) }
        case .carbs:
            recipe.carbs.flatMap { Self.parseNumeric($0) }
        case .fat:
            recipe.fat.flatMap { Self.parseNumeric($0) }
        case .protein:
            recipe.protein.flatMap { Self.parseNumeric($0) }
        }
    }

    func isAvailable(for recipe: SavedRecipe) -> Bool {
        value(for: recipe) != nil
    }

    private static func parseNumeric(_ string: String) -> Double? {
        let scanner = Scanner(string: string)
        var result: Double = 0
        if scanner.scanDouble(&result) {
            return result
        }
        return nil
    }
}

private enum GamePhase {
    case chooseStat
    case reveal
    case gameOver
}

private enum RoundResult {
    case playerWins
    case computerWins
    case tie
}

struct GameView: View {
    @Query(sort: \SavedRecipe.savedAt, order: .reverse) private var savedRecipes: [SavedRecipe]

    @State private var playerDeck: [SavedRecipe] = []
    @State private var computerDeck: [SavedRecipe] = []
    @State private var phase: GamePhase = .chooseStat
    @State private var selectedStat: GameStat? = nil
    @State private var roundResult: RoundResult? = nil
    var body: some View {
        Group {
            if savedRecipes.count < 2 {
                ContentUnavailableView("Not Enough Cards", systemImage: "rectangle.on.rectangle.angled", description: Text("You need at least 2 saved recipes to play."))
            } else {
                gameContent
            }
        }
        .navigationTitle("Game")
        .onAppear {
            if playerDeck.isEmpty && savedRecipes.count >= 2 {
                startGame()
            }
        }
    }

    @ViewBuilder
    private var gameContent: some View {
        switch phase {
        case .chooseStat, .reveal:
            roundView
        case .gameOver:
            gameOverView
        }
    }

    // MARK: - Round View

    private var isRevealed: Bool { phase == .reveal }

    private var roundView: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCounts

                if let result = roundResult, let stat = selectedStat {
                    resultBanner(result: result, stat: stat)
                } else {
                    Text("Your turn — tap a stat!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    if let card = computerDeck.first {
                        VStack(spacing: 4) {
                            Text("Computer")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            cardView(for: card, redacted: !isRevealed)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    if let card = playerDeck.first {
                        VStack(spacing: 4) {
                            Text("You")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            playerCard(card, interactive: !isRevealed)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                if isRevealed {
                    Button("Next Round") {
                        nextRound()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
                }
            }
            .padding()
        }
    }

    // MARK: - Game Over Phase

    private var gameOverView: some View {
        ContentUnavailableView {
            Label(
                playerDeck.isEmpty ? "You Lost!" : "You Won!",
                systemImage: playerDeck.isEmpty ? "hand.thumbsdown" : "trophy"
            )
        } description: {
            Text("You: \(playerDeck.count) cards — Computer: \(computerDeck.count) cards")
        } actions: {
            Button("Play Again") {
                startGame()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Subviews

    private var headerCounts: some View {
        HStack {
            Label("\(playerDeck.count)", systemImage: "person")
            Spacer()
            Label("\(computerDeck.count)", systemImage: "desktopcomputer")
        }
        .font(.headline)
        .padding(.horizontal, 4)
    }

    private func playerCard(_ recipe: SavedRecipe, interactive: Bool) -> some View {
        cardView(for: recipe)
            .environment(\.onStatTapped, interactive ? { key in
                if let stat = GameStat(rawValue: key) {
                    playStat(stat)
                }
            } : nil)
    }

    private func cardView(for recipe: SavedRecipe, redacted: Bool = false) -> some View {
        RecipeCardView(
            title: recipe.title,
            imageURL: recipe.resolvedImageURL,
            rating: recipe.rating,
            numberOfRatings: recipe.numberOfRatings,
            totalTime: recipe.totalTime,
            calories: recipe.calories,
            carbs: recipe.carbs,
            fat: recipe.fat,
            protein: recipe.protein,
            highlightedStat: selectedStat?.rawValue,
            redactStats: redacted
        )
    }

    private func resultBanner(result: RoundResult, stat: GameStat) -> some View {
        HStack {
            Image(systemName: result == .playerWins ? "checkmark.circle.fill" :
                    result == .computerWins ? "xmark.circle.fill" : "equal.circle.fill")
            Text(result == .playerWins ? "You win this round! (\(stat.label))" :
                    result == .computerWins ? "Computer wins! (\(stat.label))" :
                    "It's a tie! (\(stat.label))")
        }
        .font(.headline)
        .foregroundStyle(result == .playerWins ? .green : result == .computerWins ? .red : .orange)
    }

    // MARK: - Game Logic

    private func startGame() {
        var deck = savedRecipes.shuffled()
        let half = deck.count / 2
        playerDeck = Array(deck.prefix(half))
        computerDeck = Array(deck.suffix(from: half).prefix(half))
        phase = .chooseStat
        selectedStat = nil
        roundResult = nil
    }

    private func playStat(_ stat: GameStat) {
        guard let playerCard = playerDeck.first,
              let computerCard = computerDeck.first else { return }

        selectedStat = stat

        let playerValue = stat.value(for: playerCard) ?? 0
        let computerValue = stat.value(for: computerCard) ?? 0

        if playerValue > computerValue {
            roundResult = .playerWins
        } else if computerValue > playerValue {
            roundResult = .computerWins
        } else {
            roundResult = .tie
        }

        phase = .reveal
    }

    private func nextRound() {
        guard let playerCard = playerDeck.first,
              let computerCard = computerDeck.first else { return }

        playerDeck.removeFirst()
        computerDeck.removeFirst()

        switch roundResult {
        case .playerWins:
            playerDeck.append(playerCard)
            playerDeck.append(computerCard)
        case .computerWins:
            computerDeck.append(computerCard)
            computerDeck.append(playerCard)
        case .tie:
            playerDeck.append(playerCard)
            computerDeck.append(computerCard)
        case nil:
            break
        }

        selectedStat = nil
        roundResult = nil

        if playerDeck.isEmpty || computerDeck.isEmpty {
            phase = .gameOver
        } else {
            phase = .chooseStat
        }
    }

}

#Preview {
    NavigationStack {
        GameView()
    }
    .modelContainer(for: SavedRecipe.self, inMemory: true)
}
