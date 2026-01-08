import Foundation

class DependencyChecker {
    static let shared = DependencyChecker()
    
    // Common paths where homebrew might install ntfs-3g
    private let commonPaths = [
        "/opt/homebrew/bin/ntfs-3g",
        "/usr/local/bin/ntfs-3g",
        "/usr/bin/ntfs-3g",
        "/opt/local/bin/ntfs-3g"
    ]
    
    // Check if ntfs-3g is installed
    func isNtfs3gInstalled() -> Bool {
        // First try 'which' command
        let whichProcess = Process()
        whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        whichProcess.arguments = ["which", "ntfs-3g"]
        
        do {
            try whichProcess.run()
            whichProcess.waitUntilExit()
            if whichProcess.terminationStatus == 0 {
                return true
            }
        } catch {
            Logger.shared.log("Error checking for ntfs-3g with 'which': \(error)")
        }
        
        // Fallback to manual path checking
        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        return false
    }
    
    // Get the path to ntfs-3g executable
    func getNtfs3gPath() -> String? {
        // First try 'which' command
        let whichProcess = Process()
        whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        whichProcess.arguments = ["which", "ntfs-3g"]
        
        let pipe = Pipe()
        whichProcess.standardOutput = pipe
        
        do {
            try whichProcess.run()
            whichProcess.waitUntilExit()
            
            if whichProcess.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
                    return path
                }
            }
        } catch {
            Logger.shared.log("Error finding ntfs-3g path: \(error)")
        }
        
        // Fallback to manual path checking
        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        return nil
    }
    
    // Check for macFUSE (simplified check for kext or library)
    func isMacFuseInstalled() -> Bool {
        let fileManager = FileManager.default
        
        // Common paths for MacFUSE
        let paths = [
            "/Library/Filesystems/macfuse.fs", // New location
            "/Library/Filesystems/osxfuse.fs", // Old location
            "/usr/local/include/fuse" // Header files
        ]
        
        for path in paths {
            if fileManager.fileExists(atPath: path) {
                return true
            }
        }
        
        return false
    }
}
