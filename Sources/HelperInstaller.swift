import Foundation

struct HelperInstaller {
    static func installHelper(completion: @escaping (Bool, String) -> Void) {
        let fileManager = FileManager.default
        let helperPath = "/etc/sudoers.d/realNTFS"
        
        // Find ntfs-3g path to allow
        guard let ntfs3gPath = DependencyChecker.shared.getNtfs3gPath() else {
            completion(false, "Could not find ntfs-3g executable.")
            return
        }
        
        // This command content allows the current user to run specific commands without password
        let sudoersContent = """
        %admin ALL=(ALL) NOPASSWD: /usr/sbin/diskutil
        %admin ALL=(ALL) NOPASSWD: /bin/mkdir
        %admin ALL=(ALL) NOPASSWD: \(ntfs3gPath)
        """
        
        let tempPath = NSTemporaryDirectory() + "realNTFS_sudoers"
        
        do {
            try sudoersContent.write(toFile: tempPath, atomically: true, encoding: .utf8)
            
            // Create apple script to move the file to /etc/sudoers.d/
            let scriptSource = """
            do shell script "cp \(tempPath) \(helperPath) && chmod 440 \(helperPath) && rm \(tempPath)" with administrator privileges
            """
            
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: scriptSource) {
                scriptObject.executeAndReturnError(&error)
                if let error = error {
                    Logger.shared.log("Helper installation failed: \(error)")
                    completion(false, "Failed to install helper: \(error)")
                } else {
                    Logger.shared.log("Helper installed successfully")
                    completion(true, "Helper installed successfully")
                }
            } else {
                completion(false, "Could not create AppleScript")
            }
            
        } catch {
            completion(false, "Failed to prepare helper file: \(error.localizedDescription)")
        }
    }
    
    static func isHelperInstalled() -> Bool {
        return FileManager.default.fileExists(atPath: "/etc/sudoers.d/realNTFS")
    }
}
