import Foundation
import DiskArbitration

class DiskMonitor {
    private var session: DASession?
    var onNTFSDiskAppeared: ((String) -> Void)?
    var onDiskDisappeared: ((String) -> Void)?
    
    init() {
        self.session = DASessionCreate(kCFAllocatorDefault)
    }
    
    func startMonitoring() {
        guard let session = session else { return }
        
        DASessionScheduleWithRunLoop(session, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        
        let appearedCallback: DADiskAppearedCallback = { disk, context in
            guard let context = context else { return }
            let monitor = Unmanaged<DiskMonitor>.fromOpaque(context).takeUnretainedValue()
            monitor.handleDiskAppeared(disk: disk)
        }
        
        let disappearedCallback: DADiskDisappearedCallback = { disk, context in
            guard let context = context else { return }
            let monitor = Unmanaged<DiskMonitor>.fromOpaque(context).takeUnretainedValue()
            monitor.handleDiskDisappeared(disk: disk)
        }
        
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        let match = [
            kDADiskDescriptionVolumeMountableKey: true
        ] as CFDictionary
        
        DARegisterDiskAppearedCallback(session, match, appearedCallback, context)
        DARegisterDiskDisappearedCallback(session, match, disappearedCallback, context)
    }
    
    func stopMonitoring() {
        guard let session = session else { return }
        DASessionUnscheduleFromRunLoop(session, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
    }
    
    private func handleDiskAppeared(disk: DADisk) {
        guard let description = DADiskCopyDescription(disk) as? [String: Any] else { return }
        
        if let content = description[kDADiskDescriptionMediaContentKey as String] as? String {
            if content == "Windows_NTFS" || content == "Microsoft Basic Data" {
                if let bsdName = description[kDADiskDescriptionMediaBSDNameKey as String] as? String {
                    onNTFSDiskAppeared?(bsdName)
                }
            }
        }
    }
    
    private func handleDiskDisappeared(disk: DADisk) {
        guard let description = DADiskCopyDescription(disk) as? [String: Any] else { return }
        if let bsdName = description[kDADiskDescriptionMediaBSDNameKey as String] as? String {
            onDiskDisappeared?(bsdName)
        }
    }
}
