import OGPImageView
import SwiftUI

struct OGPImageViewDemo: View {
    @State private var urlString = "https://github.com"
    @State private var currentURL: URL?
    @State private var cacheSettings = CacheSettings()
    @State private var showingSettings = false
    @State private var pipeline = OGPPipeline()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    urlInputSection
                    fetchButton
                    imageSection
                }
                .padding()
            }
            .navigationTitle("OGPImageView Demo")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                CacheSettingsView(settings: $cacheSettings)
            }
            .onChange(of: cacheSettings) {
                updatePipelineIfNeeded()
            }
        }
    }

    private var urlInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("URL")
                .font(.headline)
            TextField("Enter URL", text: $urlString)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
        }
    }

    private var fetchButton: some View {
        Button {
            currentURL = URL(string: urlString)
        } label: {
            Text("Fetch OGP Image")
                .frame(maxWidth: .infinity)
                .padding()
                .background(urlString.isEmpty ? Color.gray : Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(urlString.isEmpty)
    }

    @ViewBuilder
    private var imageSection: some View {
        if let url = currentURL {
            VStack(alignment: .leading, spacing: 8) {
                Text(url.host ?? url.absoluteString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                OGPImageView(url: url, pipeline: pipeline) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.gray.opacity(0.2)
                            ProgressView()
                        }
                        .frame(height: 200)

                    case let .success(image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)

                    case let .failure(error):
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundStyle(.red)
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(Color.gray.opacity(0.1))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func updatePipelineIfNeeded() {
        pipeline = OGPPipeline(configuration: cacheSettings.pipelineConfiguration)
    }
}

#Preview {
    OGPImageViewDemo()
}
