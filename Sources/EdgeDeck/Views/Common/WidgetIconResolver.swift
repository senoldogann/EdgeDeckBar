import AppKit
import Foundation
import SwiftUI

@MainActor
public final class IconCache {
    public static let shared = IconCache()
    private var cache: [String: NSImage] = [:]

    private init() {}

    public func image(key: String, loader: () -> NSImage) -> NSImage {
        if let cached = cache[key] {
            return cached
        }
        let raw = loader()
        let targetSize = NSSize(width: 128.0, height: 128.0)
        let crisp = NSImage(size: targetSize)
        if let bestRep = raw.bestRepresentation(for: NSRect(origin: .zero, size: targetSize), context: nil, hints: nil) {
            crisp.addRepresentation(bestRep)
        } else {
            for rep in raw.representations {
                crisp.addRepresentation(rep)
            }
        }
        cache[key] = crisp
        return crisp
    }
}

public struct WidgetIconView: View {
    public let identifier: String
    public let size: CGFloat

    public init(identifier: String, size: CGFloat) {
        self.identifier = identifier
        self.size = size
    }

    public var body: some View {
        Group {
            if identifier == "clipboard" {
                clipboardIcon
            } else if let nsImage = resolveSystemWidgetIcon(identifier: identifier) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                fallbackIcon
            }
        }
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(0.30), radius: size * 0.08, x: 0.0, y: size * 0.04)
    }

    private func resolveSystemWidgetIcon(identifier: String) -> NSImage? {
        let key = "widget." + identifier
        return IconCache.shared.image(key: key) {
            switch identifier {
            case "weather":
                let path = "/System/Applications/Weather.app"
                if FileManager.default.fileExists(atPath: path) {
                    return NSWorkspace.shared.icon(forFile: path)
                }
            case "now_playing":
                let path = "/System/Applications/Music.app"
                if FileManager.default.fileExists(atPath: path) {
                    return NSWorkspace.shared.icon(forFile: path)
                }
            case "system_monitor":
                let path = "/System/Applications/Utilities/Activity Monitor.app"
                if FileManager.default.fileExists(atPath: path) {
                    return NSWorkspace.shared.icon(forFile: path)
                }
            case "bluetooth":
                let path = "/System/Library/PreferencePanes/Bluetooth.prefPane"
                if FileManager.default.fileExists(atPath: path) {
                    return NSWorkspace.shared.icon(forFile: path)
                }
            case "quick_notes":
                let path = "/System/Applications/Notes.app"
                if FileManager.default.fileExists(atPath: path) {
                    return NSWorkspace.shared.icon(forFile: path)
                }
            case "ai_usage":
                let siriPath = "/System/Library/PrivateFrameworks/AOSUI.framework/Versions/A/Resources/pref_siri.icns"
                if FileManager.default.fileExists(atPath: siriPath), let image = NSImage(contentsOfFile: siriPath) {
                    return image
                }
            default:
                break
            }
            return NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app")
        }
    }

    private var clipboardIcon: some View {
        let corner = size * (9.5 / 42.0)
        return ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.18, green: 0.58, blue: 0.98), location: 0.0),
                            .init(color: Color(red: 0.06, green: 0.40, blue: 0.90), location: 0.45),
                            .init(color: Color(red: 0.02, green: 0.24, blue: 0.75), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.55), location: 0.0),
                                    .init(color: Color.white.opacity(0.12), location: 0.35),
                                    .init(color: Color.clear, location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.75
                        )
                )

            Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: size * 0.50, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.white)
                .shadow(color: Color.black.opacity(0.20), radius: 1.5, x: 0.0, y: 1.0)
        }
    }

    private var fallbackIcon: some View {
        let corner = size * (9.5 / 42.0)
        return ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.35, green: 0.40, blue: 0.46), location: 0.0),
                            .init(color: Color(red: 0.20, green: 0.25, blue: 0.30), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: size * 0.48, weight: .regular))
                .foregroundColor(.white)
        }
    }
}
