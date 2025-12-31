import Foundation

// MARK: - Position
struct Position: Equatable, Hashable {
    var x: Int
    var y: Int
    
    static func == (lhs: Position, rhs: Position) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

// MARK: - Direction
enum Direction: String {
    case up, down, left, right
    
    var opposite: Direction {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }
}

// MARK: - Game State
enum GameState {
    case menu
    case playing
    case paused
    case gameOver
}

// MARK: - Game Constants
struct GameConstants {
    static let gridSize: Int = 20
    static let initialSnakeLength: Int = 5
    static let gameSpeed: Double = 0.12 // seconds between updates
    static let fastSpeed: Double = 0.08
    static let slowSpeed: Double = 0.15
}
