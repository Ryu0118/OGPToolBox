import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            OGPImageViewDemo()
                .tabItem {
                    Label("OGPImageView", systemImage: "photo")
                }

            ManualFetchDemo()
                .tabItem {
                    Label("Manual Fetch", systemImage: "arrow.down.doc")
                }
        }
    }
}

#Preview {
    ContentView()
}
