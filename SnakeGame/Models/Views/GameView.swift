import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with score and controls
            GameHeaderView(viewModel: viewModel)
            
            // Game Board
            GameBoardView(viewModel: viewModel)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { gesture in
                            handleSwipe(gesture)
                        }
                )
            
            // Direction buttons (optional, for accessibility)
            DirectionPadView(viewModel: viewModel)
            
            Spacer()
        }
        .padding()
        .overlay {
            // Pause overlay
            if viewModel.gameState == .paused {
                PauseOverlayView(viewModel: viewModel)
            }
        }
    }
    
    private func handleSwipe(_ gesture: DragGesture.Value) {
        let horizontalAmount = gesture.translation.width
        let verticalAmount = gesture.translation.height
        
        if abs(horizontalAmount) > abs(verticalAmount) {
            // Horizontal swipe
            viewModel.changeDirection(horizontalAmount > 0 ? .right : .left)
        } else {
            // Vertical swipe
            viewModel.changeDirection(verticalAmount > 0 ? .down : .up)
        }
    }
}

// MARK: - Game Header
struct GameHeaderView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        HStack {
            // Score
            VStack(alignment: .leading) {
                Text("SCORE")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(viewModel.score)")
                    .font(.title.bold())
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // High Score
            VStack {
                Text("BEST")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(viewModel.highScore)")
                    .font(.title2.bold())
                    .foregroundColor(.yellow)
            }
            
            Spacer()
            
            // Pause Button
            Button(action: {
                if viewModel.gameState == .playing {
                    viewModel.pauseGame()
                }
            }) {
                Image(systemName: "pause.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Game Board
struct GameBoardView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let cellSize = size / CGFloat(viewModel.gridSize)
            
            ZStack {
                // Background grid
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "0f0f23"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.3), lineWidth: 2)
                    )
                
                // Grid lines (subtle)
                GridLinesView(gridSize: viewModel.gridSize, cellSize: cellSize)
                
                // Food
                FoodView(
                    position: viewModel.food,
                    cellSize: cellSize
                )
                
                // Snake
                ForEach(Array(viewModel.snake.enumerated()), id: \.offset) { index, segment in
                    SnakeSegmentView(
                        position: segment,
                        cellSize: cellSize,
                        isHead: index == 0,
                        index: index,
                        totalSegments: viewModel.snake.count
                    )
                }
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Grid Lines
struct GridLinesView: View {
    let gridSize: Int
    let cellSize: CGFloat
    
    var body: some View {
        Canvas { context, size in
            let gridColor = Color.white.opacity(0.05)
            
            for i in 0...gridSize {
                let x = CGFloat(i) * cellSize
                let y = CGFloat(i) * cellSize
                
                // Vertical lines
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    },
                    with: .color(gridColor),
                    lineWidth: 0.5
                )
                
                // Horizontal lines
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    },
                    with: .color(gridColor),
                    lineWidth: 0.5
                )
            }
        }
    }
}

// MARK: - Snake Segment
struct SnakeSegmentView: View {
    let position: Position
    let cellSize: CGFloat
    let isHead: Bool
    let index: Int
    let totalSegments: Int
    
    var body: some View {
        let opacity = isHead ? 1.0 : max(0.4, 1.0 - (Double(index) / Double(totalSegments) * 0.6))
        
        RoundedRectangle(cornerRadius: isHead ? cellSize * 0.3 : cellSize * 0.2)
            .fill(
                isHead ?
                LinearGradient(
                    colors: [Color.green, Color.mint],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    colors: [Color.green.opacity(opacity), Color(hex: "228B22").opacity(opacity)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: cellSize - 2, height: cellSize - 2)
            .position(
                x: CGFloat(position.x) * cellSize + cellSize / 2,
                y: CGFloat(position.y) * cellSize + cellSize / 2
            )
            .shadow(color: isHead ? .green.opacity(0.5) : .clear, radius: 5)
    }
}

// MARK: - Food
struct FoodView: View {
    let position: Position
    let cellSize: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.red, Color(hex: "8B0000")],
                    center: .center,
                    startRadius: 0,
                    endRadius: cellSize / 2
                )
            )
            .frame(width: cellSize - 4, height: cellSize - 4)
            .scaleEffect(isAnimating ? 1.1 : 0.9)
            .position(
                x: CGFloat(position.x) * cellSize + cellSize / 2,
                y: CGFloat(position.y) * cellSize + cellSize / 2
            )
            .shadow(color: .red.opacity(0.5), radius: 5)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Direction Pad
struct DirectionPadView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            // Up
            DirectionButton(direction: .up, viewModel: viewModel)
            
            HStack(spacing: 50) {
                // Left
                DirectionButton(direction: .left, viewModel: viewModel)
                
                // Right
                DirectionButton(direction: .right, viewModel: viewModel)
            }
            
            // Down
            DirectionButton(direction: .down, viewModel: viewModel)
        }
        .padding(.top, 10)
    }
}

struct DirectionButton: View {
    let direction: Direction
    @ObservedObject var viewModel: GameViewModel
    
    var iconName: String {
        switch direction {
        case .up: return "chevron.up"
        case .down: return "chevron.down"
        case .left: return "chevron.left"
        case .right: return "chevron.right"
        }
    }
    
    var body: some View {
        Button(action: {
            viewModel.changeDirection(direction)
        }) {
            Image(systemName: iconName)
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.white.opacity(0.15))
                .cornerRadius(15)
        }
    }
}

// MARK: - Pause Overlay
struct PauseOverlayView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("PAUSED")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    Button(action: {
                        viewModel.resumeGame()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Resume")
                        }
                        .font(.title3.bold())
                        .foregroundColor(.black)
                        .frame(width: 180, height: 50)
                        .background(Color.green)
                        .cornerRadius(25)
                    }
                    
                    Button(action: {
                        viewModel.returnToMenu()
                    }) {
                        HStack {
                            Image(systemName: "house.fill")
                            Text("Main Menu")
                        }
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 180, height: 50)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(25)
                    }
                }
            }
        }
    }
}

#Preview {
    GameView(viewModel: GameViewModel())
        .preferredColorScheme(.dark)
}
