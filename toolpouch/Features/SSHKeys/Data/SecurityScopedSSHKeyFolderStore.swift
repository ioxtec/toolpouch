#if os(macOS)
import AppKit
import Foundation

@MainActor
final class SecurityScopedSSHKeyFolderStore: SSHKeyFolderAccessing {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var folderURL: URL? {
        try? resolveFolderURL()
    }

    func chooseFolder() async throws -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose SSH Key Folder"
        panel.message = "ToolPouch needs permission to read and create SSH keys in this folder."
        panel.prompt = "Choose Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.showsHiddenFiles = true

        let sshFolderURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".ssh", isDirectory: true)
        panel.directoryURL = FileManager.default.fileExists(atPath: sshFolderURL.path)
            ? sshFolderURL
            : FileManager.default.homeDirectoryForCurrentUser

        NSApp.activate(ignoringOtherApps: true)
        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return nil }

        let bookmark = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        defaults.set(bookmark, forKey: AppPreferenceKey.sshKeyFolderBookmark)
        return url
    }

    func withAccess<T: Sendable>(
        _ operation: @escaping @Sendable (URL) async throws -> T
    ) async throws -> T {
        let url = try resolveFolderURL()
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try await operation(url)
    }

    private func resolveFolderURL() throws -> URL {
        guard let bookmark = defaults.data(
            forKey: AppPreferenceKey.sshKeyFolderBookmark
        ) else {
            throw SSHKeyManagerError.folderUnavailable
        }

        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        if isStale {
            let refreshedBookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            defaults.set(
                refreshedBookmark,
                forKey: AppPreferenceKey.sshKeyFolderBookmark
            )
        }

        return url
    }
}
#endif
