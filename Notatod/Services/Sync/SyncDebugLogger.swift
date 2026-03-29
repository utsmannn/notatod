import Foundation

enum SyncDebugLogger {
    private static let logURL = URL(fileURLWithPath: "/tmp/notatod-sync-debug.log")

    static func reset() {
        try? Data().write(to: logURL, options: .atomic)
    }

    static func log(_ message: String) {
        let line = "[SyncDebug] \(message)\n"
        guard let data = line.data(using: .utf8) else { return }

        if FileManager.default.fileExists(atPath: logURL.path) == false {
            FileManager.default.createFile(atPath: logURL.path, contents: nil)
        }

        do {
            let handle = try FileHandle(forWritingTo: logURL)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
        } catch {
            try? data.write(to: logURL, options: .atomic)
        }
    }
}
