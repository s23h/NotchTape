import Foundation
import SwiftUI
import Combine

@Observable
class TickerFeedData {
    struct FeedItem: Identifiable {
        let id = UUID()
        let text: String
        let type: ItemType
        let timestamp: Date
        let url: String?
        var isRead: Bool = false
        
        enum ItemType {
            case stock
            case news
            case system
            case notification
            
            var color: Color {
                switch self {
                case .stock: return .green
                case .news: return .blue
                case .system: return .orange
                case .notification: return .purple
                }
            }
            
            var icon: String {
                switch self {
                case .stock: return "chart.line.uptrend.xyaxis"
                case .news: return "newspaper.fill"
                case .system: return "gear"
                case .notification: return "bell.fill"
                }
            }
        }
    }
    
    var items: [FeedItem] = []
    private var stockDataSource = StockDataSource.shared
    private var newsDataSource = NewsDataSource()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadInitialItems()
        setupDataSources()
    }
    
    private func loadInitialItems() {
        items = []
    }
    
    private func setupDataSources() {
        // Only subscribe to news updates (no stocks in left ticker)
        newsDataSource.$newsItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newsItems in
                self?.updateNewsItems(newsItems)
            }
            .store(in: &cancellables)
    }
    
    private func updateStockItems(_ quotes: [StockQuote]) {
        // Remove old stock items
        items.removeAll { $0.type == .stock }
        
        // Add new stock items
        let stockItems = quotes.map { quote in
            FeedItem(
                text: "\(quote.symbol) \(quote.formattedPrice) \(quote.formattedChange)",
                type: .stock,
                timestamp: Date(),
                url: "https://finance.yahoo.com/quote/\(quote.symbol)"
            )
        }
        
        items.append(contentsOf: stockItems)
        sortAndTrimItems()
    }
    
    private func updateNewsItems(_ newsItems: [NewsItem]) {
        // Remove old news items
        items.removeAll { $0.type == .news }
        
        // Add all news items for variety
        let newsFeeds = newsItems.compactMap { news -> FeedItem? in
            guard let url = news.url else { return nil }
            
            // Skip if already read
            if ReadHistoryManager.shared.isRead(url) {
                return nil
            }
            
            return FeedItem(
                text: news.title,
                type: .news,
                timestamp: news.publishedAt,
                url: url
            )
        }
        
        items.append(contentsOf: newsFeeds)
        sortAndTrimItems()
    }
    
    private func sortAndTrimItems() {
        // Separate by type
        let stocks = items.filter { $0.type == .stock }
        let news = items.filter { $0.type == .news }
        let others = items.filter { $0.type != .stock && $0.type != .news }
        
        // Interleave stocks and news for variety
        var mixed: [FeedItem] = []
        let maxCount = max(stocks.count, news.count)
        
        for i in 0..<maxCount {
            if i < stocks.count {
                mixed.append(stocks[i])
            }
            if i < news.count {
                mixed.append(news[i])
            }
        }
        
        // Add other items at the end
        mixed.append(contentsOf: others)
        
        // Keep reasonable number of items
        items = Array(mixed.prefix(50))
    }
    
    func addCustomItem(_ text: String, type: FeedItem.ItemType) {
        items.append(FeedItem(text: text, type: type, timestamp: Date(), url: nil))
        sortAndTrimItems()
    }
}