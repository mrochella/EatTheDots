import SwiftUI

struct MenuView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var isAnimating = false
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Title with animation
            VStack(spacing: 8) {
//                Text("🐍")
//                    .font(.system(size: 80))
//                    .scaleEffect(isAnimating ? 1.1 : 1.0)
//                    .animation(
//                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
//                        value: isAnimating
//                    )
                
                Text("Eat The Dots")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.green, Color.mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Classic Snake Game")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // High Score Display
            if viewModel.highScore > 0 {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("High Score: \(viewModel.highScore)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                )
            }
            
            Spacer()
            
            // Buttons
            VStack(spacing: 16) {
                // Play Button
                Button(action: {
                    viewModel.startGame()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Play")
                            .font(.title2.bold())
                    }
                    .foregroundColor(.black)
                    .frame(width: 200, height: 56)
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
                
                // Settings Button
                Button(action: {
                    showSettings = true
                }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(25)
                }
            }
            
            Spacer()
            
            // Controls hint
            VStack(spacing: 8) {
                Text("Swipe to control")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack(spacing: 20) {
                    ForEach(["arrow.left", "arrow.up", "arrow.down", "arrow.right"], id: \.self) { icon in
                        Image(systemName: icon)
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .onAppear {
            isAnimating = true
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Game Mode") {
                    Toggle("Wrap Around Walls", isOn: $viewModel.wrapAroundWalls)
                    
                    Text(viewModel.wrapAroundWalls ?
                         "Snake passes through walls" :
                         "Hitting walls ends the game")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section("Difficulty") {
                    Picker("Speed", selection: $viewModel.gameSpeed) {
                        Text("Easy").tag(GameConstants.slowSpeed)
                        Text("Normal").tag(GameConstants.gameSpeed)
                        Text("Hard").tag(GameConstants.fastSpeed)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Grid Size") {
                    Picker("Size", selection: $viewModel.gridSize) {
                        Text("Small (15)").tag(15)
                        Text("Medium (20)").tag(20)
                        Text("Large (25)").tag(25)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MenuView(viewModel: GameViewModel())
        .preferredColorScheme(.dark)
}
