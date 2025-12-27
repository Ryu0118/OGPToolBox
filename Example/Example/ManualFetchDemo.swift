import OGPImageData
import OGPMetadata
import OGPPipeline
import SwiftUI

struct ManualFetchDemo: View {
    @State private var urlString = "https://github.com"
    @State private var fetchState: FetchState = .idle
    @State private var cacheSettings = CacheSettings()
    @State private var showingSettings = false
    @State private var client = OGPClient()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    urlInputSection
                    fetchButton
                    resultSection
                }
                .padding()
            }
            .navigationTitle("Manual Fetch")
            #if !os(tvOS) && !os(watchOS)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            #endif
            .sheet(isPresented: $showingSettings) {
                CacheSettingsView(settings: $cacheSettings)
            }
        }
    }

    private var urlInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("URL")
                .font(.headline)
            TextField("Enter URL", text: $urlString)
                #if !os(tvOS)
                .textFieldStyle(.roundedBorder)
                #endif
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                #endif
        }
    }

    private var fetchButton: some View {
        Button {
            Task {
                await fetchOGPData()
            }
        } label: {
            HStack {
                if case .loading = fetchState {
                    ProgressView()
                        .tint(.white)
                }
                Text(fetchState.isLoading ? "Loading..." : "Fetch OGP")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(fetchState.isLoading ? Color.gray : Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(fetchState.isLoading || urlString.isEmpty)
    }

    @ViewBuilder
    private var resultSection: some View {
        switch fetchState {
        case .idle:
            EmptyView()

        case .loading:
            ProgressView("Fetching OGP data...")
                .padding()

        case let .success(result):
            OGPResultView(result: result)

        case let .failure(error):
            ErrorView(error: error)
        }
    }

    private func fetchOGPData() async {
        fetchState = .loading

        do {
            client.updateSettings(cacheSettings)

            guard let url = URL(string: urlString) else {
                fetchState = .failure(FetchError.invalidURL)
                return
            }

            let pipeline = client.pipeline

            async let imageDataTask = pipeline.fetchImage(from: url)
            async let metadataTask = pipeline.fetchMetadata(from: url)

            let (imageData, metadata) = try await (imageDataTask, metadataTask)

            fetchState = .success(FetchResult(metadata: metadata, imageData: imageData))
        } catch {
            fetchState = .failure(error)
        }
    }
}

#Preview {
    ManualFetchDemo()
}
