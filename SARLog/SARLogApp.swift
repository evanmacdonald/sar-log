import SwiftData
import SwiftUI

@main
struct SARLogApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try SARLogModelContainer.live()
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
