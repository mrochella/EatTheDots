import GameplayKit
import SpriteKit

// MARK: - Game State Machine
class GameStateMachine: GKStateMachine {
    
    weak var scene: GameScene?
    
    init(scene: GameScene) {
        self.scene = scene
        
        let states: [GKState] = [
            MenuState(scene: scene),
            PlayingState(scene: scene),
            PausedState(scene: scene),
            GameOverState(scene: scene)
        ]
        
        super.init(states: states)
    }
}

// MARK: - Base Game State
class BaseGameState: GKState {
    weak var scene: GameScene?
    
    init(scene: GameScene) {
        self.scene = scene
        super.init()
    }
}

// MARK: - Menu State
class MenuState: BaseGameState {
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == PlayingState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        scene?.showMenu()
    }
    
    override func willExit(to nextState: GKState) {
        scene?.hideMenu()
    }
}

// MARK: - Playing State
class PlayingState: BaseGameState {
    
    var lastUpdateTime: TimeInterval = 0
    var playerMoveAccumulator: TimeInterval = 0
    var aiMoveAccumulator: TimeInterval = 0
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == PausedState.self || stateClass == GameOverState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        if previousState is MenuState || previousState is GameOverState {
            scene?.startNewGame()
        }
        lastUpdateTime = 0
        playerMoveAccumulator = 0
        aiMoveAccumulator = 0
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        guard let scene = scene else { return }
        
        playerMoveAccumulator += seconds
        if playerMoveAccumulator >= GameConstants.playerSpeed {
            scene.movePlayerSnake()
            playerMoveAccumulator = 0
        }
        
        if scene.gameMode == .aiOpponent {
            aiMoveAccumulator += seconds
            if aiMoveAccumulator >= GameConstants.aiSpeed {
                scene.moveAISnake()
                aiMoveAccumulator = 0
            }
        }
    }
}

// MARK: - Paused State
class PausedState: BaseGameState {
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == PlayingState.self || stateClass == MenuState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        scene?.showPauseOverlay()
    }
    
    override func willExit(to nextState: GKState) {
        scene?.hidePauseOverlay()
    }
}

// MARK: - Game Over State
class GameOverState: BaseGameState {
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == PlayingState.self || stateClass == MenuState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        scene?.showGameOver()
    }
    
    override func willExit(to nextState: GKState) {
        scene?.hideGameOver()
    }
}
