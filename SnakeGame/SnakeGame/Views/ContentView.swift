import SwiftUI

struct ContentView: View {
    var body: some View {
        GameContainerView()
            .preferredColorScheme(.dark)
            .statusBarHidden()
    }
}

#Preview {
    ContentView()
}
