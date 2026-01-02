import SpriteKit
import GameplayKit

// MARK: - AI Component
class AIComponent: GKComponent {
    
    weak var snake: SnakeEntity?
    
    let randomSource: GKRandomSource
    
    var aggressiveness: Float = 0.7
    var caution: Float = 0.5
    
    init(snake: SnakeEntity) {
        self.snake = snake
        self.randomSource = GKMersenneTwisterRandomSource()
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - AI Decision Making
    func decideNextDirection() -> Direction {
        guard let snake = snake, let scene = snake.scene else {
            return snake?.currentDirection ?? .right
        }
        
        let head = snake.positions[0]
        let foodPos = scene.foodPosition
        let validDirections = Direction.allCases.filter { $0 != snake.currentDirection.opposite }
        
        var directionScores: [(Direction, Float)] = []
        for direction in validDirections {
            let score = evaluateDirection(direction, from: head, foodPos: foodPos, snake: snake, scene: scene)
            directionScores.append((direction, score))
        }
        
        directionScores.sort { $0.1 > $1.1 }
        
        let random = randomSource.nextUniform()
        
        // Only a 40% chance to pick the "Best" move.
        // 40% chance to pick the "Second Best" (which might be away from food).
        // 20% chance to pick a totally random valid move (including death moves!).
        
        if random < 0.4 {
            return directionScores[0].0 // Best
        } else if random < 0.8 {
            return directionScores[1].0 // Second best
        } else {
            // Totally random - AI might "accidentally" hit a wall or itself
            let randomIndex = Int.random(in: 0..<directionScores.count)
            return directionScores[randomIndex].0
        }
    }
    
    private func evaluateWrappedDistance(from: Int, to: Int, max: Int) -> Int {
        let d = abs(from - to)
        return min(d, max - d)
    }
    
    private func evaluateDirection(_ direction: Direction, from head: GridPosition, foodPos: GridPosition, snake: SnakeEntity, scene: GameScene) -> Float {
        var score: Float = 50.0
        
        var nextPos = GridPosition(
            x: head.x + direction.vector.x,
            y: head.y + direction.vector.y
        )
        
        if nextPos.x < 0 { nextPos.x = GameConstants.gridSize - 1 }
        if nextPos.x >= GameConstants.gridSize { nextPos.x = 0 }
        if nextPos.y < 0 { nextPos.y = GameConstants.gridSize - 1 }
        if nextPos.y >= GameConstants.gridSize { nextPos.y = 0 }
        
        for i in 0..<(snake.positions.count - 1) {
            if snake.positions[i] == nextPos { return -1000 }
        }
        if let playerSnake = scene.playerSnake {
            for pos in playerSnake.positions {
                if pos == nextPos { return -1000 }
            }
        }
        
        let currentDist = evaluateWrappedDistance(from: head.x, to: foodPos.x, max: GameConstants.gridSize) +
                          evaluateWrappedDistance(from: head.y, to: foodPos.y, max: GameConstants.gridSize)
                          
        let newDist = evaluateWrappedDistance(from: nextPos.x, to: foodPos.x, max: GameConstants.gridSize) +
                      evaluateWrappedDistance(from: nextPos.y, to: foodPos.y, max: GameConstants.gridSize)
        
        if newDist < currentDist {
            score += 30 * aggressiveness
        } else if newDist > currentDist {
            score -= 15 * aggressiveness
        }
        
        let escapeRoutes = countEscapeRoutes(from: nextPos, snake: snake, scene: scene)
        score += Float(escapeRoutes) * 10 * caution
        
        if escapeRoutes <= 1 {
            score -= 50 * caution
        }
        
        return score
    }
    
    private func countEscapeRoutes(from position: GridPosition, snake: SnakeEntity, scene: GameScene) -> Int {
        var count = 0
        
        for direction in Direction.allCases {
            var checkPos = GridPosition(
                x: position.x + direction.vector.x,
                y: position.y + direction.vector.y
            )
            
            if checkPos.x < 0 { checkPos.x = GameConstants.gridSize - 1 }
            if checkPos.x >= GameConstants.gridSize { checkPos.x = 0 }
            if checkPos.y < 0 { checkPos.y = GameConstants.gridSize - 1 }
            if checkPos.y >= GameConstants.gridSize { checkPos.y = 0 }
            
            var isSafe = true
            
            for pos in snake.positions {
                if pos == checkPos {
                    isSafe = false
                    break
                }
            }
            
            if isSafe, let playerSnake = scene.playerSnake {
                for pos in playerSnake.positions {
                    if pos == checkPos {
                        isSafe = false
                        break
                    }
                }
            }
            
            if isSafe {
                count += 1
            }
        }
        
        return count
    }
}

// MARK: - AI Difficulty Presets
extension AIComponent {
    
    static func easy(for snake: SnakeEntity) -> AIComponent {
        let ai = AIComponent(snake: snake)
        ai.aggressiveness = 0.4
        ai.caution = 0.3
        return ai
    }
    
    static func medium(for snake: SnakeEntity) -> AIComponent {
        let ai = AIComponent(snake: snake)
        ai.aggressiveness = 0.7
        ai.caution = 0.5
        return ai
    }
    
    static func hard(for snake: SnakeEntity) -> AIComponent {
        let ai = AIComponent(snake: snake)
        ai.aggressiveness = 0.9
        ai.caution = 0.8
        return ai
    }
}
