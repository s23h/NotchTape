import Foundation

class ReadHistoryManager {
    static let shared = ReadHistoryManager()
    private let userDefaults = UserDefaults.standard
    private let readLinksKey = "NotchFeed.ReadLinks"
    private let maxHistory = 1000 // Keep last 1000 read links
    
    private init() {}
    
    func markAsRead(_ url: String) {
        var readLinks = getReadLinks()
        readLinks.append(url)
        
        // Keep only recent history to prevent unlimited growth
        if readLinks.count > maxHistory {
            readLinks = Array(readLinks.suffix(maxHistory))
        }
        
        userDefaults.set(readLinks, forKey: readLinksKey)
    }
    
    func isRead(_ url: String) -> Bool {
        return getReadLinks().contains(url)
    }
    
    func getReadLinks() -> [String] {
        return userDefaults.stringArray(forKey: readLinksKey) ?? []
    }
    
    func clearHistory() {
        userDefaults.removeObject(forKey: readLinksKey)
    }
}