import SwiftUI

struct CacheSettingsView: View {
    @Binding var settings: CacheSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Cache Type") {
                    Picker("Type", selection: $settings.cacheType) {
                        ForEach(CacheType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if settings.cacheType != .none {
                    Section("Time to Live (TTL)") {
                        HStack {
                            TextField("Value", value: $settings.ttlValue, format: .number)
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #endif
                                #if !os(tvOS)
                                .textFieldStyle(.roundedBorder)
                                #endif
                                .frame(width: 80)
                            Picker("Unit", selection: $settings.ttlUnit) {
                                ForEach(TTLUnit.allCases, id: \.self) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    #if !os(tvOS)
                    Section("Limits") {
                        Stepper("Max Count: \(settings.maxCount)", value: $settings.maxCount, in: 1 ... 1000, step: 10)
                        Stepper("Max Size: \(settings.maxSizeMB) MB", value: $settings.maxSizeMB, in: 1 ... 500, step: 10)
                    }
                    #endif
                }

                Section {
                    currentSettingsSummary
                }
            }
            .navigationTitle("Cache Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            #if !os(tvOS) && !os(watchOS)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            #endif
        }
    }

    private var currentSettingsSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Settings")
                .font(.headline)
            if settings.cacheType == .none {
                Text("Caching disabled")
                    .foregroundStyle(.secondary)
            } else {
                Group {
                    Text("Type: \(settings.cacheType.rawValue)")
                    Text("TTL: \(settings.ttlValue, specifier: "%.1f") \(settings.ttlUnit.rawValue.lowercased())")
                    Text("Max entries: \(settings.maxCount)")
                    Text("Max size: \(settings.maxSizeMB) MB")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
    }
}
