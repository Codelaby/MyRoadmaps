import SwiftUI
struct AvatarToolBarDemo: View {
    var body: some View {
        NavigationStack {
            List(0..<100) { i in
                Text("Item \(i)")
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.blue.opacity(0.3)
                        .hueRotation(.degrees(Double(i) * 3.6))
                    )
            }
            .toolbar {
                // Adding a title in the center of the toolbar
                ToolbarItem(placement: .principal) {
                    Text("Center Title")
                        .font(.headline)
                }
                
                // Adding a button on the trailing side of the toolbar
                ToolbarItem(placement: .topBarTrailing) {
                    
                    Button(action: {}) {
                        Image(.dummyAvatar)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                    }
                    
                }
                //.sharedBackgroundVisibility(.hidden)
            }
            .navigationTitle("Avatar toolbar")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
        
    }
}

#Preview {
    AvatarToolBarDemo()
}
