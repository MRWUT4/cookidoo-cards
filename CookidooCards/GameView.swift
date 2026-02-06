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
    case dealing
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
    @State private var phase: GamePhase = .dealing
    @State private var selectedStat: GameStat? = nil
    @State private var roundStat: GameStat? = nil
    @State private var roundHigherWins: Bool = true
    @State private var roundResult: RoundResult? = nil
    @State private var activePlayerCardId: String?
    @State private var cardRotations: [String: Double] = [:]
    @State private var playerScore: Int = 0
    @State private var computerScore: Int = 0
    @State private var computerCardRotation: Double = 0
    var body: some View {
        Group {
            if savedRecipes.count < 2 {
                ContentUnavailableView("Not Enough Cards", systemImage: "rectangle.on.rectangle.angled", description: Text("You need at least 2 saved recipes to play."))
            } else {
                gameContent
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .onAppear {
            if playerDeck.isEmpty && savedRecipes.count >= 2 {
                startGame()
            }
        }
    }

    @ViewBuilder
    private var gameContent: some View {
        switch phase {
        case .dealing, .chooseStat, .reveal:
            roundView
        case .gameOver:
            gameOverView
                .transition(.opacity)
        }
    }

    // MARK: - Round View

    private var isRevealed: Bool { phase == .reveal }
    private var cardsOnScreen: Bool { phase == .chooseStat || phase == .reveal }

    private var roundView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                headerCounts

                if let stat = roundStat {
                    Label(stat.label, systemImage: roundHigherWins ? "chevron.up" : "chevron.down")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                if let result = roundResult, let stat = selectedStat {
                    resultBanner(result: result, stat: stat)
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: -20) {
                if let card = computerDeck.first {
                    VStack(spacing: 4) {
                        Text("Computer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        cardView(for: card, redacted: !isRevealed)
                            .rotationEffect(.degrees(computerCardRotation))
                    }
                    .frame(maxWidth: .infinity)
                }

                VStack(spacing: 4) {
                    Text("You (\(activeCardIndex + 1)/\(playerDeck.count))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    playerHandView
                }
            }

            Spacer(minLength: 0)

            if isRevealed {
                Button("Next Round") {
                    nextRound()
                }
                .buttonStyle(.borderedProminent)
            } else if cardsOnScreen {
                Button("Compare") {
                    compareCards()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Game Over Phase

    private var gameOverTitle: String {
        if playerScore > computerScore { return "You Won!" }
        if computerScore > playerScore { return "You Lost!" }
        return "It's a Draw!"
    }

    private var gameOverIcon: String {
        if playerScore > computerScore { return "trophy" }
        if computerScore > playerScore { return "hand.thumbsdown" }
        return "equal.circle"
    }

    private var gameOverView: some View {
        ContentUnavailableView {
            Label(gameOverTitle, systemImage: gameOverIcon)
        } description: {
            Text("You: \(playerScore) — Computer: \(computerScore)")
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
            Label("\(playerScore)", systemImage: "person")
            Spacer()
            Text("\(playerDeck.count) left")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Label("\(computerScore)", systemImage: "desktopcomputer")
        }
        .font(.headline)
        .padding(.horizontal, 4)
    }

    private var activeCardIndex: Int {
        guard let id = activePlayerCardId,
              let index = playerDeck.firstIndex(where: { $0.recipeId == id })
        else { return 0 }
        return index
    }

    private var playerHandView: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(playerDeck) { card in
                    cardView(for: card)
                        .rotationEffect(.degrees(cardRotations[card.recipeId] ?? 0))
                        .containerRelativeFrame(.horizontal)
                        .scrollTransition(.animated(.spring(duration: 0.4, bounce: 0.2))) { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1 : 0.5)
                                .scaleEffect(phase.isIdentity ? 1 : 0.85)
                                .rotationEffect(.degrees(phase.value * 8))
                                .offset(y: phase.isIdentity ? 0 : 20)
                        }
                        .id(card.recipeId)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $activePlayerCardId)
        .scrollIndicators(.hidden)
        .scrollDisabled(isRevealed)
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
            redactStats: redacted,
            scale: 1
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
        let deck = savedRecipes.shuffled()
        let half = deck.count / 2
        playerDeck = Array(deck.prefix(half))
        computerDeck = Array(deck.suffix(from: half).prefix(half))
        selectedStat = nil
        roundStat = pickRandomStat()
        roundHigherWins = Bool.random()
        roundResult = nil
        playerScore = 0
        computerScore = 0
        activePlayerCardId = playerDeck.first?.recipeId
        computerCardRotation = Double.random(in: -6...6)
        generateCardRotations()
        phase = .dealing

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
                phase = .chooseStat
            }
        }
    }

    private var activePlayerCard: SavedRecipe? {
        guard let id = activePlayerCardId else { return playerDeck.first }
        return playerDeck.first { $0.recipeId == id }
    }

    private func compareCards() {
        guard let stat = roundStat,
              let playerCard = activePlayerCard,
              let computerCard = computerDeck.first else { return }

        selectedStat = stat

        let playerValue = stat.value(for: playerCard) ?? 0
        let computerValue = stat.value(for: computerCard) ?? 0

        let playerBetter = roundHigherWins ? playerValue > computerValue : playerValue < computerValue
        let computerBetter = roundHigherWins ? computerValue > playerValue : computerValue < playerValue

        if playerBetter {
            roundResult = .playerWins
        } else if computerBetter {
            roundResult = .computerWins
        } else {
            roundResult = .tie
        }

        phase = .reveal
    }

    private func pickRandomStat() -> GameStat {
        GameStat.allCases.randomElement() ?? .rating
    }

    private func generateCardRotations() {
        var rotations: [String: Double] = [:]
        for card in playerDeck {
            rotations[card.recipeId] = Double.random(in: -6...6)
        }
        cardRotations = rotations
    }

    private func nextRound() {
        guard let playerCard = activePlayerCard,
              let playerIndex = playerDeck.firstIndex(where: { $0.recipeId == playerCard.recipeId })
        else { return }

        switch roundResult {
        case .playerWins:
            playerScore += 1
        case .computerWins:
            computerScore += 1
        case .tie, nil:
            break
        }

        playerDeck.remove(at: playerIndex)
        computerDeck.removeFirst()

        selectedStat = nil
        roundResult = nil
        roundStat = pickRandomStat()
        roundHigherWins = Bool.random()
        activePlayerCardId = playerDeck.first?.recipeId
        computerCardRotation = Double.random(in: -6...6)

        if playerDeck.isEmpty || computerDeck.isEmpty {
            withAnimation(.easeIn(duration: 0.4)) {
                phase = .dealing
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    phase = .gameOver
                }
            }
        } else {
            phase = .chooseStat
        }
    }

}

#Preview {
    let container = try! ModelContainer(for: SavedRecipe.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    let recipes: [(String, String, Double, Int, Int, String, String, String, String)] = [
        ("Spaghetti Bolognese", "r1", 4.3, 128, 2400, "350 kcal", "45 g", "12 g", "18 g"),
        ("Chicken Tikka Masala", "r2", 4.7, 256, 3600, "480 kcal", "30 g", "22 g", "35 g"),
        ("Caesar Salad", "r3", 3.9, 64, 1200, "220 kcal", "15 g", "14 g", "12 g"),
        ("Beef Stroganoff", "r4", 4.1, 92, 3000, "520 kcal", "38 g", "28 g", "32 g"),
        ("Pad Thai", "r5", 4.5, 180, 1800, "410 kcal", "52 g", "16 g", "20 g"),
        ("Mushroom Risotto", "r6", 4.0, 75, 2700, "380 kcal", "55 g", "10 g", "9 g"),
    ]

    for (title, id, rating, reviews, time, cal, carbs, fat, protein) in recipes {
        let recipe = Recipe(id: id, title: title, rating: rating, numberOfRatings: reviews, publishedAt: nil, image: nil, totalTime: time, objectID: nil, descriptiveAssets: nil)
        let nutrition = NutritionInfo(calories: cal, carbohydrateContent: carbs, fatContent: fat, proteinContent: protein)
        container.mainContext.insert(SavedRecipe(recipe: recipe, nutrition: nutrition))
    }

    return NavigationStack {
        GameView()
    }
    .modelContainer(container)
}
