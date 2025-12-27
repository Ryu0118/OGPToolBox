import SwiftUI

struct ErrorView: View {
    let error: Error

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text("Error")
                .font(.headline)
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
