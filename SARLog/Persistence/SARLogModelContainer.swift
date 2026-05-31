import Foundation
import SwiftData

enum SARLogModelContainer {
    static let storeFileName = "SARLog.store"

    static var schema: Schema {
        Schema([
            SARTask.self,
            TimelineEvent.self,
            VitalsEntry.self,
        ])
    }

    @MainActor
    static func live() throws -> ModelContainer {
        let url = try liveStoreURL()
        try BackupEligibility.includeInBackup(url.deletingLastPathComponent())
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        try BackupEligibility.includeInBackup(url)
        return container
    }

    @MainActor
    static func inMemory() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    @MainActor
    static func persistent(at url: URL) throws -> ModelContainer {
        try BackupEligibility.includeInBackup(url.deletingLastPathComponent())
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        try BackupEligibility.includeInBackup(url)
        return container
    }

    static func liveStoreURL(fileManager: FileManager = .default) throws -> URL {
        let directory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appendingPathComponent("SARLog", isDirectory: true)

        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(storeFileName)
    }
}

enum BackupEligibility {
    static func includeInBackup(_ url: URL, fileManager: FileManager = .default) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        var includedURL = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = false
        try includedURL.setResourceValues(values)
    }

    static func isIncludedInBackup(_ url: URL) throws -> Bool {
        let values = try url.resourceValues(forKeys: [.isExcludedFromBackupKey])
        return values.isExcludedFromBackup != true
    }
}
