import Foundation
import Combine

class Logger: ObservableObject {
    static let shared = Logger()
    @Published var logs: [String] = []
    
    private init() {}
    
    func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)"
        print(logMessage)
        
        DispatchQueue.main.async {
            self.logs.append(logMessage)
            // Keep log buffer reasonable
            if self.logs.count > 1000 {
                self.logs.removeFirst(self.logs.count - 1000)
            }
        }
    }
    
    func clear() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
}
