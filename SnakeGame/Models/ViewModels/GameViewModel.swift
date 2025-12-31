import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var snake: [Position] = []
    @Published var food: Position = Position(x: 0, y: 0)
    @Published var score: Int = 0
    @Published var highScore: Int = 0
    @Published var gameState: GameState = .menu
    @Published var currentDirection: Direction = .right
    
    // MARK: - Game Settings
    @Published var gridSize: Int = GameConstants.gridSize
    @Published var gameSpeed: Double = GameConstants.gameSpeed
    @Published var wrapAroundWalls: Bool = true // Your original game had this!
    
    // MARK: - Private Properties
    private var gameTimer: Timer?
    private var nextDirection: Direction = .right
    private let haptics = UIImpactFeedbackGenerator(style: .medium)
    private let heavyHaptics = UIImpactFeedbackGenerator(style: .heavy)
    
    // MARK: - UserDefaults Keys
    private let highScoreKey = "SnakeHighScore"
    
    // MARK: - Initialization
    init() {
        loadHighScore()
    }
    
    // MARK: - Game Control Methods
    func startGame() {
        resetGame()
        gameState = .playing
        startGameLoop()
        haptics.impactOccurred()
    }
    
    func pauseGame() {
        gameState = .paused
        stopGameLoop()
    }
    
    func resumeGame() {
        gameState = .playing
        startGameLoop()
    }
    
    func returnToMenu() {
        stopGameLoop()
        gameState = .menu
    }
    
    // MARK: - Direction Control
    func changeDirection(_ newDirection: Direction) {
        // Prevent 180-degree turns (same as your original!)
        if newDirection.opposite != currentDirection {
            nextDirection = newDirection
            haptics.impactOccurred(intensity: 0.5)
        }
    }
    
    // MARK: - Private Methods
    private func resetGame() {
        snake.removeAll()
        score = 0
        currentDirection = .right
        nextDirection = .right
        
        // Create initial snake in the middle-left area
        let startX = gridSize / 4
        let startY = gridSize / 2
        
        for i in 0..<GameConstants.initialSnakeLength {
            snake.append(Position(x: startX - i, y: startY))
        }
        
        spawnFood()
    }
    
    private func startGameLoop() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: gameSpeed, repeats: true) { [weak self] _ in
            self?.updateGame()
        }
    }
    
    private func stopGameLoop() {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    private func updateGame() {
        guard gameState == .playing else { return }
        
        // Update direction
        currentDirection = nextDirection
        
        // Calculate new head position
        guard let head = snake.first else { return }
        var newHead = head
        
        switch currentDirection {
        case .up:
            newHead.y -= 1
        case .down:
            newHead.y += 1
        case .left:
            newHead.x -= 1
        case .right:
            newHead.x += 1
        }
        
        // Handle wall collision (wrap around like your original!)
        if wrapAroundWalls {
            if newHead.x < 0 { newHead.x = gridSize - 1 }
            if newHead.x >= gridSize { newHead.x = 0 }
            if newHead.y < 0 { newHead.y = gridSize - 1 }
            if newHead.y >= gridSize { newHead.y = 0 }
        } else {
            // Wall collision = game over
            if newHead.x < 0 || newHead.x >= gridSize ||
               newHead.y < 0 || newHead.y >= gridSize {
                gameOver()
                return
            }
        }
        
        // Check self collision (skip the tail since it will move)
        let bodyToCheck = snake.dropLast()
        if bodyToCheck.contains(newHead) {
            gameOver()
            return
        }
        
        // Move snake
        snake.insert(newHead, at: 0)
        
        // Check food collision
        if newHead == food {
            eatFood()
        } else {
            snake.removeLast()
        }
    }
    
    private func spawnFood() {
        var newFood: Position
        repeat {
            newFood = Position(
                x: Int.random(in: 0..<gridSize),
                y: Int.random(in: 0..<gridSize)
            )
        } while snake.contains(newFood)
        
        food = newFood
    }
    
    private func eatFood() {
        score += 1
        haptics.impactOccurred()
        spawnFood()
        
        // Increase speed slightly as score increases (optional challenge)
        if score % 5 == 0 && gameSpeed > 0.05 {
            gameSpeed -= 0.005
            restartGameLoop()
        }
    }
    
    private func restartGameLoop() {
        stopGameLoop()
        startGameLoop()
    }
    
    private func gameOver() {
        stopGameLoop()
        heavyHaptics.impactOccurred()
        gameState = .gameOver
        
        if score > highScore {
            highScore = score
            saveHighScore()
        }
    }
    
    // MARK: - Persistence
    private func loadHighScore() {
        highScore = UserDefaults.standard.integer(forKey: highScoreKey)
    }
    
    private func saveHighScore() {
        UserDefaults.standard.set(highScore, forKey: highScoreKey)
    }
}
