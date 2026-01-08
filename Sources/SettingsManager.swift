import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    @AppStorage("autoStartAtLogin") var autoStartAtLogin: Bool = false {
        didSet {
            handleAutoStart(autoStartAtLogin)
        }
    }
    @AppStorage("autoMountOnLaunch") var autoMountOnLaunch: Bool = false
    @AppStorage("autoMountNewDrives") var autoMountNewDrives: Bool = false
    @AppStorage("helperInstalled") var helperInstalled: Bool = false
    
    static let shared = SettingsManager()
    
    init() {
        // Verify if helper is actually installed
        if helperInstalled {
            if !FileManager.default.fileExists(atPath: "/etc/sudoers.d/realNTFS") {
                helperInstalled = false
            }
        } else {
             if FileManager.default.fileExists(atPath: "/etc/sudoers.d/realNTFS") {
                helperInstalled = true
            }
        }
    }
    
    private func handleAutoStart(_ shouldStart: Bool) {
        let launchAgentDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
        let plistPath = launchAgentDir.appendingPathComponent("com.example.realNTFS.plist")
        
        if shouldStart {
            // Create LaunchAgent
            let appPath = Bundle.main.bundlePath
            let plistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>com.example.realNTFS</string>
                <key>ProgramArguments</key>
                <array>
                    <string>/usr/bin/open</string>
                    <string>\(appPath)</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
            </dict>
            </plist>
            """
            
            do {
                try FileManager.default.createDirectory(at: launchAgentDir, withIntermediateDirectories: true)
                try plistContent.write(to: plistPath, atomically: true, encoding: .utf8)
            } catch {
                print("Failed to create LaunchAgent: \(error)")
            }
        } else {
            // Remove LaunchAgent
            try? FileManager.default.removeItem(at: plistPath)
        }
    }
}
