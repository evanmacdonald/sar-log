import SwiftUI

struct LocationConvertSheet: View {
    let initialText: String
    let onApply: (String) -> Void

    @State private var viewModel = ConverterViewModel()
    @State private var showingMap = false
    @State private var didSeed = false
    @Environment(\.dismiss) private var dismiss
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                inputSection
                formatSection
                formattedSection
                outputSection
            }
            .navigationTitle("GPS Converter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.parsedCoordinate != nil {
                        Button {
                            showingMap = true
                        } label: {
                            Label("Map", systemImage: "map")
                        }
                        .accessibilityLabel("Show map")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingMap) {
                if let coord = viewModel.parsedCoordinate {
                    LocationMapView(coordinate: coord)
                }
            }
        }
        .onAppear {
            guard !didSeed else { return }
            didSeed = true
            viewModel.inputText = initialText
            viewModel.convert()
        }
    }

    private func runConvert() {
        inputFocused = false
        viewModel.formatOverridden = false
        viewModel.convert()
    }

    private var inputSection: some View {
        Section("Coordinate") {
            TextField("Enter coordinates (any format)", text: $viewModel.inputText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($inputFocused)
                .onSubmit { runConvert() }

            Button("Convert") {
                runConvert()
            }
            .frame(maxWidth: .infinity)

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private var formatSection: some View {
        if viewModel.detectedFormat != nil || viewModel.formatOverridden {
            Section(viewModel.formatOverridden ? "Input Format" : "Detected: \(viewModel.selectedFormat.rawValue)") {
                Picker("Format", selection: Binding(
                    get: { viewModel.selectedFormat },
                    set: { viewModel.overrideFormat($0) }
                )) {
                    ForEach(CoordinateFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var formattedSection: some View {
        if let formatted = viewModel.formattedInput {
            Section("Formatted Input") {
                formatRow(label: viewModel.selectedFormat.rawValue, value: formatted)
            }
        }
    }

    @ViewBuilder
    private var outputSection: some View {
        if !viewModel.outputs.isEmpty {
            Section("Converted") {
                ForEach(viewModel.outputs) { row in
                    formatRow(label: row.format.rawValue, value: row.value)
                }
            }
        }
    }

    private func formatRow(label: String, value: String) -> some View {
        Button {
            onApply(value)
            dismiss()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.body.monospaced())
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Text("Use")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Use \(label): \(value)")
    }
}
