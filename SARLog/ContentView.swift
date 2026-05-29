import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "cross.case")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.red)
                    .accessibilityHidden(true)

                Text("SAR Log")
                    .font(.largeTitle.bold())

                Text("Ready for task logging.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .navigationTitle("SAR Log")
        }
    }
}

