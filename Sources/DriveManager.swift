import Foundation

struct Drive: Identifiable, Hashable {
    let id: String
    let name: String
    let size: String
    let type: String
    let mountPoint: String?
    
    var isNTFS: Bool {
        return type == "Windows_NTFS" || type == "Microsoft Basic Data"
    }
}

class DriveManager: ObservableObject {
    @Published var drives: [Drive] = []
    @Published var errorMessage: String?
    @Published var isMounting = false
    
    private var diskMonitor: DiskMonitor?
    // Keep track of mounted volumes to clean up on disconnect
    private var mountedVolumes: [String: String] = [:] // id -> mountPoint
    
    init() {
        if SettingsManager.shared.autoMountNewDrives {
            startMonitoring()
        }
    }
    
    func startMonitoring() {
        diskMonitor = DiskMonitor()
        diskMonitor?.onNTFSDiskAppeared = { [weak self] bsdName in
            Logger.shared.log("New NTFS disk detected: \(bsdName)")
            self?.refreshDrives {
                if let drive = self?.drives.first(where: { $0.id == bsdName }) {
                    self?.mountNTFS(drive: drive)
                }
            }
        }
        diskMonitor?.onDiskDisappeared = { [weak self] bsdName in
            Logger.shared.log("Disk disappeared: \(bsdName)")
            self?.handleDiskDisappeared(id: bsdName)
            self?.refreshDrives()
        }
        diskMonitor?.startMonitoring()
    }
    
    func stopMonitoring() {
        diskMonitor?.stopMonitoring()
        diskMonitor = nil
    }
    
    private func handleDiskDisappeared(id: String) {
        // Check if we have a known mount point for this drive
        // Note: We might not have it in 'mountedVolumes' if it was mounted before app launch
        // But we can try to infer or just rely on what we tracked.
        
        if let mountPoint = mountedVolumes[id] {
            Logger.shared.log("Cleaning up mount point for \(id): \(mountPoint)")
            // Force unmount to ensure FUSE cleans up
            DispatchQueue.global(qos: .background).async {
                do {
                    // Try umount first
                    try Shell.runWithAdmin("umount \"\(mountPoint)\"")
                } catch {
                    // If that fails, try diskutil unmount force
                    try? Shell.runWithAdmin("diskutil unmount force \"\(mountPoint)\"")
                }
            }
            mountedVolumes.removeValue(forKey: id)
        }
    }
    
    func refreshDrives(completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let output = try Shell.run("diskutil list -plist")
                guard let data = output.data(using: .utf8) else {
                    DispatchQueue.main.async { completion?() }
                    return
                }
                
                if let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
                   let allDisksAndPartitions = plist["AllDisksAndPartitions"] as? [[String: Any]] {
                    
                    var newDrives: [Drive] = []
                    
                    for disk in allDisksAndPartitions {
                        if let partitions = disk["Partitions"] as? [[String: Any]] {
                            for partition in partitions {
                                if let deviceIdentifier = partition["DeviceIdentifier"] as? String {
                                    let name = partition["VolumeName"] as? String ?? "Untitled"
                                    let sizeVal = partition["Size"] as? Int ?? 0
                                    let size = ByteCountFormatter.string(fromByteCount: Int64(sizeVal), countStyle: .file)
                                    let type = partition["Content"] as? String ?? ""
                                    let mountPoint = partition["MountPoint"] as? String
                                    
                                    if type == "Windows_NTFS" || type == "Microsoft Basic Data" {
                                        newDrives.append(Drive(id: deviceIdentifier, name: name, size: size, type: type, mountPoint: mountPoint))
                                    }
                                }
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.drives = newDrives
                        completion?()
                    }
                } else {
                    DispatchQueue.main.async { completion?() }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to list drives: \(error.localizedDescription)"
                    completion?()
                }
            }
        }
    }
    
    func mountAll() {
        refreshDrives {
            for drive in self.drives {
                self.mountNTFS(drive: drive)
            }
        }
    }
    
    func mountNTFS(drive: Drive) {
        isMounting = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            let deviceNode = "/dev/\(drive.id)"
            let safeName = drive.name.isEmpty ? "NTFS_Drive" : drive.name.replacingOccurrences(of: "/", with: "_")
            let mountPoint = "/Volumes/\(safeName)"
            
            let ntfsCmd = "if [ -f /opt/homebrew/bin/ntfs-3g ]; then echo /opt/homebrew/bin/ntfs-3g; elif [ -f /usr/local/bin/ntfs-3g ]; then echo /usr/local/bin/ntfs-3g; else echo ntfs-3g; fi"
            
            do {
                let ntfsPath = try Shell.run(ntfsCmd).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if HelperInstaller.isHelperInstalled() {
                    Logger.shared.log("Helper installed, running commands individually")
                    
                    do {
                        try Shell.runWithAdmin("diskutil unmount \(deviceNode)")
                    } catch {
                        let nsError = error as NSError
                        let errorOutput = nsError.userInfo[NSLocalizedDescriptionKey] as? String ?? ""
                        if errorOutput.contains("already unmounted") {
                            Logger.shared.log("Volume already unmounted, proceeding.")
                        } else {
                            throw error
                        }
                    }
                    
                    try Shell.runWithAdmin("mkdir -p \"\(mountPoint)\"")
                    
                    let mountCmd = "\(ntfsPath) \(deviceNode) \"\(mountPoint)\" -olocal -oallow_other -o auto_xattr -ovolname=\"\(drive.name)\""
                    _ = try Shell.runWithAdmin(mountCmd)
                    
                    // Track mounted volume
                    DispatchQueue.main.async {
                        self.mountedVolumes[drive.id] = mountPoint
                    }
                    
                } else {
                    Logger.shared.log("Helper NOT installed, running as script")
                    let script = """
                    diskutil unmount \(deviceNode);
                    mkdir -p "\(mountPoint)";
                    \(ntfsPath) \(deviceNode) "\(mountPoint)" -olocal -oallow_other -o auto_xattr -ovolname="\(drive.name)"
                    """
                    _ = try Shell.runWithAdmin(script)
                    
                    DispatchQueue.main.async {
                }
                    _ = try Shell.runWithAdmin(script)
                }
                
                DispatchQueue.main.async {
                    self.isMounting = false
                    self.refreshDrives()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isMounting = false
                    self.errorMessage = "Failed to mount: \(error.localizedDescription)"
                }
            }
        }
    }
}
