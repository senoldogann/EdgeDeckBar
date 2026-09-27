import Foundation

public final class ApplicationCatalogService: @unchecked Sendable {
    public init() {
    }

    public func scan(directories: [URL]) -> [ApplicationDescriptor] {
        var results: [ApplicationDescriptor] = []
        var seenBundleIDs = Set<String>()

        for dir in directories {
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.isApplicationKey],
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }

            for url in contents where url.pathExtension == "app" {
                guard let bundle = Bundle(url: url) else { continue }
                let bundleID = bundle.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
                if seenBundleIDs.contains(bundleID) {
                    continue
                }
                seenBundleIDs.insert(bundleID)

                let displayName = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                    ?? url.deletingPathExtension().lastPathComponent

                results.append(
                    ApplicationDescriptor(
                        bundleIdentifier: bundleID,
                        displayName: displayName,
                        applicationURL: url
                    )
                )
            }
        }

        return results.sorted {
            $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
        }
    }
}
