import SwiftUI
import SpriteKit
import Combine
import GameplayKit

// MARK: - SpriteKit View Wrapper
struct SpriteKitContainer: UIViewRepresentable {
    let scene: GameScene
    
    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.presentScene(scene)
        view.ignoresSiblingOrder = true
        view.showsFPS = false
        view.showsNodeCount = false
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {}
}

// MARK: - Game Container View
struct GameContainerView: View {
    @StateObject private var gameController = GameController()
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.black, Color(hex: "0a0a1a")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // SpriteKit Scene
            SpriteKitContainer(scene: gameController.scene)
                .ignoresSafeArea()
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { gesture in
                            handleSwipe(gesture)
                        }
                )
            
            // UI Overlay based on state
            VStack {
                // Top bar
                if gameController.isPlaying {
                    HStack {
                        Spacer()
                        Button(action: {
                            gameController.togglePause()
                        }) {
                            Image(systemName: gameController.isPaused ? "play.fill" : "pause.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(12)
                        }
                        .padding()
                    }
                }
                
                Spacer()
                
                // Menu overlay
                if gameController.showMenu {
                    MenuOverlay(gameController: gameController)
                        .transition(.opacity)
                }
                
                // Game over overlay
                if gameController.showGameOver {
                    GameOverOverlay(gameController: gameController)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Direction buttons
                if gameController.isPlaying && !gameController.isPaused {
                    DirectionButtons(gameController: gameController)
                        .padding(.bottom, 30)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: gameController.showMenu)
        .animation(.easeInOut(duration: 0.3), value: gameController.showGameOver)
    }
    
    private func handleSwipe(_ gesture: DragGesture.Value) {
        let horizontal = gesture.translation.width
        let vertical = gesture.translation.height
        
        if abs(horizontal) > abs(vertical) {
            gameController.scene.handleSwipe(horizontal > 0 ? .right : .left)
        } else {
            gameController.scene.handleSwipe(vertical < 0 ? .up : .down)
        }
    }
}

// MARK: - Game Controller
class GameController: ObservableObject {
    let scene: GameScene
    
    @Published var showMenu = true
    @Published var showGameOver = false
    @Published var isPlaying = false
    @Published var isPaused = false
    @Published var score = 0
    @Published var highScore = 0
    @Published var isNewHighScore = false
    @Published var selectedMode: GameMode = .classic
    
    init() {
        let scene = GameScene(size: CGSize(width: 400, height: 800))
        scene.scaleMode = .resizeFill
        
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        self.scene = scene
        
        // Observe scene changes
        scene.onScoreUpdate = { [weak self] score, highScore in
            DispatchQueue.main.async {
                self?.score = score
                self?.highScore = highScore
            }
        }
        
        scene.onGameOver = { [weak self] finalScore, isHighScore in
            DispatchQueue.main.async {
                self?.score = finalScore
                self?.isNewHighScore = isHighScore
                self?.showGameOver = true
                self?.isPlaying = false
            }
        }
    }
    
    func startGame(mode: GameMode) {
        selectedMode = mode
        scene.gameMode = mode
        scene.stateMachine.enter(PlayingState.self)
        
        showMenu = false
        showGameOver = false
        isPlaying = true
        isPaused = false
        isNewHighScore = false
    }
    
    func togglePause() {
        scene.togglePause()
        isPaused = scene.stateMachine.currentState is PausedState
    }
    
    func returnToMenu() {
        scene.stateMachine.enter(MenuState.self)
        showMenu = true
        showGameOver = false
        isPlaying = false
        isPaused = false
    }
    
    func setDirection(_ direction: Direction) {
        scene.handleSwipe(direction)
    }
}

// MARK: - Menu Overlay
struct MenuOverlay: View {
    @ObservedObject var gameController: GameController
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Title
            VStack(spacing: 8) {
                Text("Eat The Dots")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Classic Snake Game")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 190)
            
            // High Score
            if gameController.highScore > 0 {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("Best: \(gameController.highScore)")
                        .foregroundColor(.white)
                }
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.white.opacity(0.1)))
            }
            
            // Mode Selection
            VStack(spacing: 12) {
                ForEach(GameMode.allCases, id: \.self) { mode in
                    Button(action: {
                        gameController.startGame(mode: mode)
                    }) {
                        HStack {
                            modeIcon(for: mode)
                            Text(mode.rawValue)
                                .font(.title3.bold())
                        }
                        .foregroundColor(mode == .aiOpponent ? .black : .white)
                        .frame(width: 200, height: 50)
                        .background(
                            mode == .aiOpponent ?
                            AnyShapeStyle(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)) :
                            AnyShapeStyle(Color.white.opacity(0.15))
                        )
                        .cornerRadius(25)
                    }
                }
            }
            
            // Controls hint
            VStack(spacing: 4) {
                Text("Swipe or use buttons to move")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    @ViewBuilder
    private func modeIcon(for mode: GameMode) -> some View {
        switch mode {
        case .classic:
            Image(systemName: "play.fill")
        case .aiOpponent:
            Image(systemName: "person.2.fill")
        }
    }
}

// MARK: - Game Over Overlay
struct GameOverOverlay: View {
    @ObservedObject var gameController: GameController
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 25) {
            // Title
            Text("Game Over")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            // Score
            VStack(spacing: 8) {
                Text("Score")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(gameController.score)")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // New high score
            if gameController.isNewHighScore {
                HStack {
                    Text("New High Score!")
                }
                .font(.headline)
                .foregroundColor(.yellow)
                .padding()
            }
            
            // Buttons
            VStack(spacing: 12) {
                Button(action: {
                    gameController.startGame(mode: gameController.selectedMode)
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Play Again")
                            .font(.title3.bold())
                    }
                    .foregroundColor(.black)
                    .frame(width: 200, height: 50)
                    .background(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(25)
                    .padding(.bottom, 20)
                }
                
                Button(action: {
                    gameController.returnToMenu()
                }) {
                    HStack {
                        Image(systemName: "house.fill")
                        Text("Menu")
                    }
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(25)
                }
            }
        }
        .padding(200)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Direction Buttons
struct DirectionButtons: View {
    @ObservedObject var gameController: GameController
    
    var body: some View {
        VStack(spacing: 5) {
            DirectionButton(direction: .up, action: { gameController.setDirection(.up) })
            
            HStack(spacing: 50) {
                DirectionButton(direction: .left, action: { gameController.setDirection(.left) })
                DirectionButton(direction: .right, action: { gameController.setDirection(.right) })
            }
            
            DirectionButton(direction: .down, action: { gameController.setDirection(.down) })
        }
    }
}

struct DirectionButton: View {
    let direction: Direction
    let action: () -> Void
    
    var iconName: String {
        switch direction {
        case .up: return "chevron.up"
        case .down: return "chevron.down"
        case .left: return "chevron.left"
        case .right: return "chevron.right"
        }
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.title.bold())
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.white.opacity(0.2))
                .cornerRadius(15)
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

#Preview {
    GameContainerView()
}
