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
        let sshFolderURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".ssh", isDirectory: true)
        let initialDirectory = FileManager.default.fileExists(atPath: sshFolderURL.path)
            ? sshFolderURL
            : FileManager.default.homeDirectoryForCurrentUser

        guard let url = CenteredFilePanel.chooseDirectory(
            title: "Choose SSH Key Folder",
            message: "ToolPouch needs permission to read and create SSH keys in this folder.",
            initialDirectory: initialDirectory,
            showsHiddenFiles: true
        ) else { return nil }

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
