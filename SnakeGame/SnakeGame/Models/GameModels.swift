import Foundation
import SpriteKit

// MARK: - Grid Position
struct GridPosition: Equatable, Hashable {
    var x: Int
    var y: Int
    
    func toScenePosition(cellSize: CGFloat, gridOffset: CGPoint) -> CGPoint {
        return CGPoint(
            x: gridOffset.x + CGFloat(x) * cellSize + cellSize / 2,
            y: gridOffset.y + CGFloat(y) * cellSize + cellSize / 2
        )
    }
    
    static func fromScenePosition(_ point: CGPoint, cellSize: CGFloat, gridOffset: CGPoint) -> GridPosition {
        return GridPosition(
            x: Int((point.x - gridOffset.x) / cellSize),
            y: Int((point.y - gridOffset.y) / cellSize)
        )
    }
}

// MARK: - Direction
enum Direction: CaseIterable {
    case up, down, left, right
    
    var opposite: Direction {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }
    
    var vector: (x: Int, y: Int) {
        switch self {
        case .up: return (0, 1)
        case .down: return (0, -1)
        case .left: return (-1, 0)
        case .right: return (1, 0)
        }
    }
    
    var angle: CGFloat {
        switch self {
        case .up: return .pi / 2
        case .down: return -.pi / 2
        case .left: return .pi
        case .right: return 0
        }
    }
}

// MARK: - Snake Type
enum SnakeType {
    case player
    case ai
    
    var headColor: SKColor {
        switch self {
        case .player: return SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0)
        case .ai: return SKColor(red: 0.8, green: 0.3, blue: 0.8, alpha: 1.0)
        }
    }
    
    var bodyColor: SKColor {
        switch self {
        case .player: return SKColor(red: 0.1, green: 0.6, blue: 0.2, alpha: 1.0)
        case .ai: return SKColor(red: 0.6, green: 0.2, blue: 0.6, alpha: 1.0)
        }
    }
}

// MARK: - Game Mode
enum GameMode: String, CaseIterable {
    case classic = "Classic"
    case aiOpponent = "VS AI"
}

// MARK: - Game Constants
struct GameConstants {
    static let gridSize: Int = 20
    static let cellSize: CGFloat = 18
    
    static let playerSpeed: TimeInterval = 0.12
    static let aiSpeed: TimeInterval = 0.15
    
    static let initialLength: Int = 5
    
    struct Category {
        static let none: UInt32 = 0
        static let snake: UInt32 = 0x1 << 0
        static let food: UInt32 = 0x1 << 1
        static let wall: UInt32 = 0x1 << 2
        static let aiSnake: UInt32 = 0x1 << 3
    }
    
    struct ZPosition {
        static let background: CGFloat = 0
        static let grid: CGFloat = 1
        static let food: CGFloat = 2
        static let snake: CGFloat = 3
        static let particles: CGFloat = 4
        static let ui: CGFloat = 10
    }
}
