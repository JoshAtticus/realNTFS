import Foundation

struct Shell {
    @discardableResult
    static func run(_ command: String) throws -> String {
        Logger.shared.log("Shell run: \(command)")
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.standardInput = nil
        
        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        if task.terminationStatus != 0 {
            Logger.shared.log("Shell error (code \(task.terminationStatus)): \(output)", type: .error)
            throw NSError(domain: "Shell", code: Int(task.terminationStatus), userInfo: [NSLocalizedDescriptionKey: output])
        } else {
            Logger.shared.log("Shell output: \(output)")
        }
        
        return output
    }
    
    static func runWithAdmin(_ command: String) throws -> String {
        Logger.shared.log("Shell runWithAdmin: \(command)")
        
        // Check if we can run without password (helper installed)
        if HelperInstaller.isHelperInstalled() {
            // Try running with sudo directly
            let sudoCommand = "sudo -n \(command)"
            do {
                Logger.shared.log("Attempting sudo -n: \(sudoCommand)")
                return try run(sudoCommand)
            } catch {
                Logger.shared.log("sudo -n failed, falling back to AppleScript", type: .info)
            }
        }
        
        // Escape double quotes and backslashes for AppleScript
        let escapedCommand = command.replacingOccurrences(of: "\\", with: "\\\\")
                                    .replacingOccurrences(of: "\"", with: "\\\"")
        
        let appleScript = "do shell script \"\(escapedCommand)\" with administrator privileges"
        
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-e", appleScript]
        task.launchPath = "/usr/bin/osascript"
        
        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        if task.terminationStatus != 0 {
            Logger.shared.log("AppleScript error: \(output)", type: .error)
            throw NSError(domain: "Shell", code: Int(task.terminationStatus), userInfo: [NSLocalizedDescriptionKey: output])
        }
        
        Logger.shared.log("AppleScript output: \(output)")
        return output
    }
}
