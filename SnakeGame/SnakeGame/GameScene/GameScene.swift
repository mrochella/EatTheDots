import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    // MARK: - Game State
    var stateMachine: GameStateMachine!
    var gameMode: GameMode = .classic
    
    // MARK: - Entities
    var playerSnake: SnakeEntity?
    var aiSnake: SnakeEntity?
    
    // MARK: - Food
    var foodPosition: GridPosition = GridPosition(x: 10, y: 10)
    var foodNode: SKSpriteNode?
    
    // MARK: - Grid
    var gridOffset: CGPoint = .zero
    var gridNode: SKNode?
    
    // MARK: - Score
    var playerScore: Int = 0
    var aiScore: Int = 0
    var highScore: Int = 0
    
    // MARK: - UI Nodes
    var scoreLabel: SKLabelNode?
    var highScoreLabel: SKLabelNode?
    var menuNode: SKNode?
    var pauseOverlay: SKNode?
    var gameOverNode: SKNode?
    
    // MARK: - Random Source (GameplayKit)
    let randomSource = GKRandomDistribution(lowestValue: 0, highestValue: GameConstants.gridSize - 1)
    
    // MARK: - Callbacks
    var onScoreUpdate: ((Int, Int) -> Void)?
    var onGameOver: ((Int, Bool) -> Void)?
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        
        loadHighScore()
        calculateGridOffset()
        setupGrid()
        setupUI()
        
        stateMachine = GameStateMachine(scene: self)
        stateMachine.enter(MenuState.self)
    }
    
    private func calculateGridOffset() {
        let gridWidth = CGFloat(GameConstants.gridSize) * GameConstants.cellSize
        let gridHeight = CGFloat(GameConstants.gridSize) * GameConstants.cellSize
        
        let verticalShift: CGFloat = 100
        
        gridOffset = CGPoint(
            x: -gridWidth / 2,
            y: (-gridHeight / 2) + verticalShift
        )
    }

    private func setupGrid() {
        gridNode?.removeFromParent()
        gridNode = SKNode()
        gridNode?.zPosition = GameConstants.ZPosition.grid
        
        let gridWidth = CGFloat(GameConstants.gridSize) * GameConstants.cellSize
        let gridHeight = CGFloat(GameConstants.gridSize) * GameConstants.cellSize
        
        let verticalShift = gridOffset.y + (gridHeight / 2)
        
        let background = SKShapeNode(rectOf: CGSize(width: gridWidth, height: gridHeight), cornerRadius: 8)
        background.position = CGPoint(x: 0, y: verticalShift)
        
        background.fillColor = SKColor(red: 0.08, green: 0.08, blue: 0.15, alpha: 1.0)
        background.strokeColor = SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 0.5)
        background.lineWidth = 2
        gridNode?.addChild(background)
        
        for i in 0...GameConstants.gridSize {
        let x = gridOffset.x + CGFloat(i) * GameConstants.cellSize
        let y = gridOffset.y + CGFloat(i) * GameConstants.cellSize
        
        let vLine = SKShapeNode()
        let vPath = CGMutablePath()
        vPath.move(to: CGPoint(x: x, y: gridOffset.y))
        vPath.addLine(to: CGPoint(x: x, y: -gridOffset.y)) // go to top
        vLine.path = vPath
        vLine.strokeColor = SKColor.white.withAlphaComponent(0.05)
        vLine.lineWidth = 0.5
        gridNode?.addChild(vLine)
        
        // Horizontal line
        let hLine = SKShapeNode()
        let hPath = CGMutablePath()
        hPath.move(to: CGPoint(x: gridOffset.x, y: y))
        hPath.addLine(to: CGPoint(x: -gridOffset.x, y: y)) // go to right
        hLine.path = hPath
        hLine.strokeColor = SKColor.white.withAlphaComponent(0.05)
        hLine.lineWidth = 0.5
        gridNode?.addChild(hLine)
        }
        
        addChild(gridNode!)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        let gridWidth = CGFloat(GameConstants.gridSize) * GameConstants.cellSize
        let gridHeight = CGFloat(GameConstants.gridSize) * GameConstants.cellSize
        
        let labelYPosition = gridOffset.y + gridHeight + 10
        let leftEdge = gridOffset.x
        let rightEdge = gridOffset.x + gridWidth
        
        scoreLabel?.removeFromParent()
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel?.fontSize = 22
        scoreLabel?.fontColor = .white
        scoreLabel?.horizontalAlignmentMode = .left
        scoreLabel?.verticalAlignmentMode = .bottom
        scoreLabel?.position = CGPoint(x: leftEdge, y: labelYPosition)
        scoreLabel?.zPosition = GameConstants.ZPosition.ui
        scoreLabel?.text = "Score: 0"
        if let scoreLabel = scoreLabel { addChild(scoreLabel) }
        
        highScoreLabel?.removeFromParent()
        highScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        highScoreLabel?.fontSize = 16
        highScoreLabel?.fontColor = SKColor.yellow
        highScoreLabel?.horizontalAlignmentMode = .right
        highScoreLabel?.verticalAlignmentMode = .bottom
        highScoreLabel?.position = CGPoint(x: rightEdge, y: labelYPosition + 2)
        highScoreLabel?.zPosition = GameConstants.ZPosition.ui
        highScoreLabel?.text = "Best: \(highScore)"
        if let highScoreLabel = highScoreLabel { addChild(highScoreLabel) }
    }
    
    // MARK: - Game Control
    func startNewGame() {
        playerSnake?.removeFromScene()
        aiSnake?.removeFromScene()
        foodNode?.removeFromParent()
        
        playerScore = 0
        aiScore = 0
        updateScoreDisplay()
        
        let playerStart = GridPosition(x: 5, y: GameConstants.gridSize / 2)
        playerSnake = SnakeEntity(type: .player, startPosition: playerStart, scene: self)
        
        if gameMode == .aiOpponent {
            let aiStart = GridPosition(x: GameConstants.gridSize - 6, y: GameConstants.gridSize / 2)
            aiSnake = SnakeEntity(type: .ai, startPosition: aiStart, scene: self)
            aiSnake?.currentDirection = .left
            aiSnake?.nextDirection = .left
        }
        
        spawnFood()
    }
    
    // MARK: - Food
    func spawnFood() {
        foodNode?.removeFromParent()
        
        var validPosition = false
        var attempts = 0
        
        while !validPosition && attempts < 100 {
            foodPosition = GridPosition(
                x: randomSource.nextInt(),
                y: randomSource.nextInt()
            )
            
            validPosition = true
            
            if let snake = playerSnake {
                for pos in snake.positions {
                    if pos == foodPosition {
                        validPosition = false
                        break
                    }
                }
            }
            
            if validPosition, let snake = aiSnake {
                for pos in snake.positions {
                    if pos == foodPosition {
                        validPosition = false
                        break
                    }
                }
            }
            
            attempts += 1
        }
        
        let foodSize = GameConstants.cellSize - 4
        foodNode = SKSpriteNode(color: .clear, size: CGSize(width: foodSize, height: foodSize))
        foodNode?.position = foodPosition.toScenePosition(cellSize: GameConstants.cellSize, gridOffset: gridOffset)
        foodNode?.zPosition = GameConstants.ZPosition.food
        
        let apple = SKShapeNode(circleOfRadius: foodSize / 2)
        apple.fillColor = SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        apple.strokeColor = SKColor(red: 0.7, green: 0.1, blue: 0.1, alpha: 1.0)
        apple.lineWidth = 2
        foodNode?.addChild(apple)
        
        let glow = SKEffectNode()
        glow.shouldRasterize = true
        glow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 5.0])
        let glowCircle = SKShapeNode(circleOfRadius: foodSize / 2)
        glowCircle.fillColor = SKColor.red.withAlphaComponent(0.5)
        glowCircle.strokeColor = .clear
        glow.addChild(glowCircle)
        foodNode?.addChild(glow)
        
        let scaleUp = SKAction.scale(to: 1.15, duration: 0.5)
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.5)
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        foodNode?.run(SKAction.repeatForever(pulse))
        
        foodNode?.setScale(0)
        foodNode?.run(SKAction.scale(to: 1.0, duration: 0.2))
        
        addChild(foodNode!)
    }
    
    // MARK: - Snake Movement
    func movePlayerSnake() {
        guard let snake = playerSnake else { return }
        
        let result = snake.move()
        handleMoveResult(result, for: snake, isPlayer: true)
    }
    
    func moveAISnake() {
        guard let snake = aiSnake else { return }
        
        if let aiComponent = snake.component(ofType: AIComponent.self) {
            let direction = aiComponent.decideNextDirection()
            snake.setDirection(direction)
        }
        
        let result = snake.move()
        handleMoveResult(result, for: snake, isPlayer: false)
    }
    
    private func handleMoveResult(_ result: MoveResult, for snake: SnakeEntity, isPlayer: Bool) {
        switch result {
        case .ateFood:
            let eatPosition = foodNode?.position ?? .zero
            
            if isPlayer {
                playerScore += 1
            } else {
                aiScore += 1
            }
            updateScoreDisplay()
            
            spawnEatParticles(at: eatPosition)
            playEatSound()

            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            spawnFood()
            
        case .collision:
            if isPlayer {
                gameOver(playerWon: false)
            } else {
                gameOver(playerWon: true)
            }
            
        default:
            break
        }
    }
    
    func getOtherSnake(for snake: SnakeEntity) -> SnakeEntity? {
        if snake === playerSnake {
            return aiSnake
        } else {
            return playerSnake
        }
    }
    
    // MARK: - Particles (SpriteKit)
    func spawnEatParticles(at position: CGPoint) {
        let particleColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0) // Brighter red
        
        for _ in 0..<15 {
            let particle = SKShapeNode(rectOf: CGSize(width: 5, height: 5), cornerRadius: 1)
            particle.fillColor = particleColor
            particle.strokeColor = .clear
            particle.position = position
            
            particle.zPosition = GameConstants.ZPosition.particles + 10
            
            particle.blendMode = .add
            
            addChild(particle)
            
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let distance = CGFloat.random(in: 25...60)
            let targetPos = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )
            
            let move = SKAction.move(to: targetPos, duration: 0.4)
            move.timingMode = .easeOut
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -4...4), duration: 0.4)
            let scale = SKAction.scale(to: 0, duration: 0.4)
            let fade = SKAction.fadeOut(withDuration: 0.4)
            
            let group = SKAction.group([move, rotate, scale, fade])
            
            particle.run(SKAction.sequence([group, .removeFromParent()]))
        }
    }
    
    func spawnDeathParticles(at positions: [CGPoint], color: SKColor) {
        for position in positions {
            for _ in 0..<5 {
                let particle = SKShapeNode(rectOf: CGSize(width: 6, height: 6))
                particle.fillColor = color
                particle.strokeColor = .clear
                particle.position = position
                particle.zPosition = GameConstants.ZPosition.particles
                addChild(particle)
                
                let angle = CGFloat.random(in: 0...(.pi * 2))
                let distance = CGFloat.random(in: 30...60)
                let targetPos = CGPoint(
                    x: position.x + cos(angle) * distance,
                    y: position.y + sin(angle) * distance
                )
                
                let move = SKAction.move(to: targetPos, duration: 0.5)
                move.timingMode = .easeOut
                let fade = SKAction.fadeOut(withDuration: 0.5)
                let scale = SKAction.scale(to: 0, duration: 0.5)
                let group = SKAction.group([move, fade, scale])
                let remove = SKAction.removeFromParent()
                
                particle.run(SKAction.sequence([group, remove]))
            }
        }
    }
    
    // MARK: - Sound
    func playEatSound() {
        run(SKAction.playSoundFileNamed("eat.wav", waitForCompletion: false))
    }
    
    func playGameOverSound() {
        run(SKAction.playSoundFileNamed("gameover.wav", waitForCompletion: false))
    }
    
    // MARK: - Score
    private func updateScoreDisplay() {
        if gameMode == .aiOpponent {
            scoreLabel?.text = "You: \(playerScore)  AI: \(aiScore)"
        } else {
            scoreLabel?.text = "Score: \(playerScore)"
        }
        onScoreUpdate?(playerScore, highScore)
    }
    
    // MARK: - Game Over
    func gameOver(playerWon: Bool) {
        if let snake = playerSnake {
            let positions = snake.segments.map({ $0.position })
            
            spawnDeathParticles(at: Array(positions.prefix(5)), color: snake.snakeType.headColor)
        }
        
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -10, y: 0, duration: 0.05),
            SKAction.moveBy(x: 20, y: 0, duration: 0.05),
            SKAction.moveBy(x: -20, y: 0, duration: 0.05),
            SKAction.moveBy(x: 10, y: 0, duration: 0.05)
        ])
        gridNode?.run(shake)
        
        let finalScore = playerScore
        if finalScore > highScore {
            highScore = finalScore
            saveHighScore()
            highScoreLabel?.text = "Best: \(highScore)"
        }
        
        playGameOverSound()
        
        stateMachine.enter(GameOverState.self)
        onGameOver?(finalScore, finalScore >= highScore)
    }
    
    // MARK: - Menu/Overlays
    func showMenu() {
        gridNode?.isHidden = true
        scoreLabel?.isHidden = true
        highScoreLabel?.isHidden = true
        foodNode?.isHidden = true
    }

    func hideMenu() {
        gridNode?.isHidden = false
        scoreLabel?.isHidden = false
        highScoreLabel?.isHidden = false
        foodNode?.isHidden = false
        
        gridNode?.alpha = 1.0
    }
    
    func showPauseOverlay() {
        pauseOverlay = SKNode()
        pauseOverlay?.zPosition = 100
        
        let dimmer = SKShapeNode(rectOf: size)
        dimmer.fillColor = SKColor.black.withAlphaComponent(0.7)
        dimmer.strokeColor = .clear
        dimmer.position = .zero
        pauseOverlay?.addChild(dimmer)
        
        let pauseLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        pauseLabel.text = "PAUSED"
        pauseLabel.fontSize = 48
        pauseLabel.fontColor = .white
        pauseLabel.verticalAlignmentMode = .center
        pauseLabel.position = .zero
        pauseOverlay?.addChild(pauseLabel)
        
        addChild(pauseOverlay!)
        
        self.isPaused = true
    }

    func hidePauseOverlay() {
        pauseOverlay?.removeFromParent()
        pauseOverlay = nil
        self.isPaused = false
    }
    
    // MARK: - Game Over Visibility
    func showGameOver() {
        gridNode?.isHidden = true
        scoreLabel?.isHidden = true
        highScoreLabel?.isHidden = true
        foodNode?.isHidden = true
        
        playerSnake?.removeFromScene()
        aiSnake?.removeFromScene()
    }

    func hideGameOver() {
        gridNode?.isHidden = false
        scoreLabel?.isHidden = false
        highScoreLabel?.isHidden = false
        foodNode?.isHidden = false
        
        gridNode?.alpha = 1.0
    }
    
    // MARK: - Input
    func handleSwipe(_ direction: Direction) {
        if stateMachine.currentState is PlayingState {
            playerSnake?.setDirection(direction)
        }
    }
    
    func togglePause() {
        if stateMachine.currentState is PlayingState {
            stateMachine.enter(PausedState.self)
        } else if stateMachine.currentState is PausedState {
            stateMachine.enter(PlayingState.self)
        }
    }
    
    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        guard !self.isPaused else { return }
        
        stateMachine?.update(deltaTime: 1.0 / 60.0)
    }
    
    // MARK: - Persistence
    private func loadHighScore() {
        highScore = UserDefaults.standard.integer(forKey: "SnakeHighScore")
    }
    
    private func saveHighScore() {
        UserDefaults.standard.set(highScore, forKey: "SnakeHighScore")
    }
}
