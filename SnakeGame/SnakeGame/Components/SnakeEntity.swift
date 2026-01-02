import SpriteKit
import GameplayKit

// MARK: - Snake Entity
class SnakeEntity: GKEntity {
    
    let snakeType: SnakeType
    var segments: [SKSpriteNode] = []
    var positions: [GridPosition] = []
    var currentDirection: Direction = .right
    var nextDirection: Direction = .right
    
    weak var scene: GameScene?
    
    // MARK: - Initialization
    init(type: SnakeType, startPosition: GridPosition, scene: GameScene) {
        self.snakeType = type
        self.scene = scene
        super.init()
        
        if type == .ai {
            let aiComponent = AIComponent(snake: self)
            addComponent(aiComponent)
        }
        
        createInitialBody(at: startPosition)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Snake Creation
    private func createInitialBody(at startPosition: GridPosition) {
        guard let scene = scene else { return }
        
        for i in 0..<GameConstants.initialLength {
            let position = GridPosition(x: startPosition.x - i, y: startPosition.y)
            positions.append(position)
            
            let segment = createSegment(isHead: i == 0)
            segment.position = position.toScenePosition(
                cellSize: GameConstants.cellSize,
                gridOffset: scene.gridOffset
            )
            scene.addChild(segment)
            segments.append(segment)
        }
    }
    
    private func createSegment(isHead: Bool) -> SKSpriteNode {
        let size = CGSize(
            width: GameConstants.cellSize - 2,
            height: GameConstants.cellSize - 2
        )
        
        let segment = SKSpriteNode(color: isHead ? snakeType.headColor : snakeType.bodyColor, size: size)
        segment.zPosition = GameConstants.ZPosition.snake
        
        if isHead {
            segment.size = CGSize(
                width: GameConstants.cellSize - 1,
                height: GameConstants.cellSize - 1
            )
            
            let glow = SKEffectNode()
            glow.shouldRasterize = true
            glow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 3.0])
            
            let glowSprite = SKSpriteNode(color: snakeType.headColor, size: size)
            glowSprite.alpha = 0.5
            glow.addChild(glowSprite)
            segment.addChild(glow)
            
            addEyes(to: segment)
        }
        
        segment.name = isHead ? "head" : "body"
        
        return segment
    }
    
    private func addEyes(to head: SKSpriteNode) {
        let eyeSize: CGFloat = 4
        let eyeOffset: CGFloat = 4
        
        for side in [-1.0, 1.0] {
            let eye = SKShapeNode(circleOfRadius: eyeSize / 2)
            eye.fillColor = .white
            eye.strokeColor = .clear
            eye.position = CGPoint(x: eyeOffset, y: CGFloat(side) * 3)
            eye.zPosition = 1
            
            let pupil = SKShapeNode(circleOfRadius: eyeSize / 4)
            pupil.fillColor = .black
            pupil.strokeColor = .clear
            pupil.position = CGPoint(x: 1, y: 0)
            eye.addChild(pupil)
            
            head.addChild(eye)
        }
    }
    
    // MARK: - Movement
    func setDirection(_ direction: Direction) {
        if direction.opposite != nextDirection {
            nextDirection = direction
        }
    }
    
    func move() -> MoveResult {
        guard let scene = scene else { return .none }
        
        currentDirection = nextDirection
        
        let head = positions[0]
        var newHead = GridPosition(
            x: head.x + currentDirection.vector.x,
            y: head.y + currentDirection.vector.y
        )
        
        if newHead.x < 0 { newHead.x = GameConstants.gridSize - 1 }
        if newHead.x >= GameConstants.gridSize { newHead.x = 0 }
        if newHead.y < 0 { newHead.y = GameConstants.gridSize - 1 }
        if newHead.y >= GameConstants.gridSize { newHead.y = 0 }
        
        for i in 0..<(positions.count - 1) {
            if positions[i] == newHead {
                return .collision
            }
        }
        
        if let otherSnake = scene.getOtherSnake(for: self) {
            for pos in otherSnake.positions {
                if pos == newHead {
                    return .collision
                }
            }
        }
        
        let tailPosition = positions.last!
        
        positions.insert(newHead, at: 0)
        positions.removeLast()
        
        updateSegmentPositions()
        
        if let headSprite = segments.first {
            headSprite.zRotation = currentDirection.angle
        }
        
        if newHead == scene.foodPosition {
            grow(at: tailPosition)
            return .ateFood
        }
        
        return .moved
    }
    
    private func updateSegmentPositions() {
        guard let scene = scene else { return }
        
        let maxNormalMove = GameConstants.cellSize * 2
        
        for (index, segment) in segments.enumerated() {
            let targetPosition = positions[index].toScenePosition(
                cellSize: GameConstants.cellSize,
                gridOffset: scene.gridOffset
            )
            
            let distance = hypot(targetPosition.x - segment.position.x, targetPosition.y - segment.position.y)
            
            if distance > maxNormalMove {
                segment.removeAllActions()
                segment.position = targetPosition
            } else {
                let moveAction = SKAction.move(to: targetPosition, duration: 0.05)
                moveAction.timingMode = .easeOut
                segment.run(moveAction)
            }
        }
    }
    
    func grow(at position: GridPosition) {
        guard let scene = scene else { return }
        
        positions.append(position)
        
        let segment = createSegment(isHead: false)
        segment.position = position.toScenePosition(
            cellSize: GameConstants.cellSize,
            gridOffset: scene.gridOffset
        )
        
        segment.setScale(0)
        segment.run(SKAction.scale(to: 1.0, duration: 0.15))
        
        scene.addChild(segment)
        segments.append(segment)
    }
    
    // MARK: - Cleanup
    func removeFromScene() {
        for segment in segments {
            segment.removeFromParent()
        }
        segments.removeAll()
        positions.removeAll()
    }
}

// MARK: - Move Result
enum MoveResult {
    case none
    case moved
    case ateFood
    case collision
}
