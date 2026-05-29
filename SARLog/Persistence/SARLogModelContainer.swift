import Foundation
import SwiftData

enum SARLogModelContainer {
    static var schema: Schema {
        Schema([
            SARTask.self,
        ])
    }

    @MainActor
    static func live() throws -> ModelContainer {
        try ModelContainer(for: schema)
    }

    @MainActor
    static func inMemory() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    @MainActor
    static func persistent(at url: URL) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, url: url)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
