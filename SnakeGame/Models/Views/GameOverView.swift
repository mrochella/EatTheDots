import SwiftUI

struct GameOverView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var isAnimating = false
    @State private var showNewHighScore = false
    
    var isNewHighScore: Bool {
        viewModel.score == viewModel.highScore && viewModel.score > 0
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Game Over Title
            VStack(spacing: 12) {
                Text("💀")
                    .font(.system(size: 60))
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0.0)
                
                Text("GAME OVER")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.red)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.0)
            }
            
            // Score Display
            VStack(spacing: 20) {
                // Current Score
                VStack(spacing: 4) {
                    Text("YOUR SCORE")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(viewModel.score)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .opacity(isAnimating ? 1.0 : 0.0)
                .offset(y: isAnimating ? 0 : 20)
                
                // New High Score Badge
                if isNewHighScore {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("NEW HIGH SCORE!")
                            .font(.headline.bold())
                            .foregroundColor(.yellow)
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.yellow.opacity(0.2))
                    )
                    .scaleEffect(showNewHighScore ? 1.0 : 0.5)
                    .opacity(showNewHighScore ? 1.0 : 0.0)
                }
                
                // High Score
                if !isNewHighScore {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                        Text("Best: \(viewModel.highScore)")
                            .foregroundColor(.gray)
                    }
                    .font(.subheadline)
                    .opacity(isAnimating ? 1.0 : 0.0)
                }
            }
            
            Spacer()
            
            // Buttons
            VStack(spacing: 16) {
                // Play Again Button
                Button(action: {
                    viewModel.startGame()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Play Again")
                            .font(.title2.bold())
                    }
                    .foregroundColor(.black)
                    .frame(width: 220, height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
                    .shadow(color: .green.opacity(0.5), radius: 10, y: 5)
                }
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .opacity(isAnimating ? 1.0 : 0.0)
                
                // Main Menu Button
                Button(action: {
                    viewModel.returnToMenu()
                }) {
                    HStack {
                        Image(systemName: "house.fill")
                        Text("Main Menu")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                    .frame(width: 220, height: 50)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(25)
                }
                .opacity(isAnimating ? 1.0 : 0.0)
            }
            
            Spacer()
            
            // Stats (optional - shows how long you survived)
            VStack(spacing: 4) {
                Text("Snake Length: \(viewModel.score + 5)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 30)
            .opacity(isAnimating ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
            
            if isNewHighScore {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        showNewHighScore = true
                    }
                }
            }
        }
        .onDisappear {
            isAnimating = false
            showNewHighScore = false
        }
    }
}

#Preview {
    GameOverView(viewModel: {
        let vm = GameViewModel()
        vm.score = 15
        vm.highScore = 15
        return vm
    }())
    .preferredColorScheme(.dark)
}
