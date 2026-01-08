import SwiftUI

struct ContentView: View {
    @StateObject private var driveManager = DriveManager()
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var logger = Logger.shared
    @State private var showSettings = false
    @State private var showLogs = false
    @State private var missingDependencies: [String] = []
    @State private var selectedDriveId: String?
    
    var body: some View {
        NavigationView {
            VStack {
                List(selection: $selectedDriveId) {
                    Section(header: Text("NTFS Drives")) {
                        if driveManager.drives.isEmpty {
                            Text("No drives found")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        } else {
                            ForEach(driveManager.drives) { drive in
                                NavigationLink(
                                    destination: DriveDetailView(drive: drive, driveManager: driveManager),
                                    tag: drive.id,
                                    selection: $selectedDriveId
                                ) {
                                    HStack {
                                        Image(systemName: "internaldrive")
                                        Text(drive.name)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(SidebarListStyle())
                
                Divider()
                
                HStack {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                    }
                    .help("Settings")
                    
                    Spacer()
                    
                    Button(action: { showLogs = true }) {
                        Image(systemName: "list.bullet.rectangle")
                    }
                    .help("Logs")
                }
                .padding(8)
            }
            .frame(minWidth: 200)
            
            Text("Select a drive")
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 700, minHeight: 400)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { driveManager.refreshDrives() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh Drives")
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(driveManager: driveManager)
        }
        .sheet(isPresented: $showLogs) {
            LogsView()
        }
        .onAppear {
            checkDependencies()
            driveManager.refreshDrives()
            if settings.autoMountOnLaunch {
                driveManager.mountAll()
            }
        }
    }
    
    func checkDependencies() {
        var missing: [String] = []
        if DependencyChecker.isNTFS3GInstalled() == nil {
            missing.append("ntfs-3g")
            Logger.shared.log("ntfs-3g not found", type: .error)
        }
        if !DependencyChecker.isMacFUSEInstalled() {
            missing.append("macFUSE")
            Logger.shared.log("macFUSE not found", type: .error)
        }
        missingDependencies = missing
    }
}

struct DriveDetailView: View {
    let drive: Drive
    @ObservedObject var driveManager: DriveManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "internaldrive.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text(drive.name)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                InfoRow(label: "Device ID", value: drive.id)
                InfoRow(label: "Size", value: drive.size)
                InfoRow(label: "Type", value: drive.type)
                InfoRow(label: "Mount Point", value: drive.mountPoint ?? "Not Mounted")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Spacer()
            
            HStack {
                if drive.mountPoint == nil || drive.mountPoint?.hasPrefix("/Volumes") == false {
                     Button(action: {
                         driveManager.mountNTFS(drive: drive)
                     }) {
                         Text("Mount R/W")
                             .frame(minWidth: 100)
                     }
                     .disabled(driveManager.isMounting)
                     .controlSize(.large)
                } else {
                    Text("Mounted")
                        .foregroundColor(.green)
                        .font(.headline)
                    
                    Button(action: {
                        driveManager.mountNTFS(drive: drive)
                    }) {
                        Text("Remount R/W")
                    }
                    .disabled(driveManager.isMounting)
                }
            }
            
            if driveManager.isMounting {
                ProgressView("Mounting...")
            }
            
            if let error = driveManager.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .trailing)
            Text(value)
                .fontWeight(.medium)
            Spacer()
        }
    }
}

struct LogsView: View {
    @ObservedObject var logger = Logger.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            HStack {
                Text("Logs")
                    .font(.title)
                Spacer()
                Button("Export") {
                    let logContent = logger.logs.map { "[\($0.timestamp)] [\($0.type)] \($0.message)" }.joined(separator: "\n")
                    let savePanel = NSSavePanel()
                    savePanel.allowedContentTypes = [.text]
                    savePanel.nameFieldStringValue = "realNTFS.log"
                    savePanel.begin { response in
                        if response == .OK, let url = savePanel.url {
                            try? logContent.write(to: url, atomically: true, encoding: .utf8)
                        }
                    }
                }
                Button("Clear") {
                    logger.clear()
                }
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding()
            
            List(logger.logs) { log in
                HStack(alignment: .top) {
                    Text(log.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(log.message)
                        .foregroundColor(log.type.color)
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .frame(width: 600, height: 400)
    }
}

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var driveManager: DriveManager
    @Environment(\.presentationMode) var presentationMode
    @State private var installError: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.title)
            
            Toggle("Start at Login", isOn: $settings.autoStartAtLogin)
            Toggle("Auto-mount on Launch", isOn: $settings.autoMountOnLaunch)
            Toggle("Auto-mount New Drives", isOn: $settings.autoMountNewDrives)
                .onChange(of: settings.autoMountNewDrives) { newValue in
                    if newValue {
                        driveManager.startMonitoring()
                    } else {
                        driveManager.stopMonitoring()
                    }
                }
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("Helper Tool")
                    .font(.headline)
                Text("Install the helper tool to mount drives without asking for a password every time.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if settings.helperInstalled {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Helper Installed")
                            .foregroundColor(.green)
                    }
                } else {
                    Button("Install Helper") {
                        do {
                            try HelperInstaller.installHelper()
                            installError = nil
                        } catch {
                            installError = error.localizedDescription
                        }
                    }
                }
                
                if let error = installError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("Credits")
                    .font(.headline)
                Text("Created by JoshAtticus")
                    .font(.caption)
                Text("Uses ntfs-3g and macFUSE")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .padding()
        .frame(width: 400, height: 450)
    }
}
