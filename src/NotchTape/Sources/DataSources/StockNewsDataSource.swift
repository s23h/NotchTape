import Foundation

struct StockNewsItem: Codable {
    let title: String
    let link: String?
    let pubDate: String?
    let source: String?
}

class StockNewsDataSource {
    static let shared = StockNewsDataSource()
    
    private init() {}
    
    func fetchNews(for symbol: String, completion: @escaping (String?) -> Void) {
        // Using Yahoo Finance RSS feed for stock-specific news
        let urlString = "https://feeds.finance.yahoo.com/rss/2.0/headline?s=\(symbol)&region=US&lang=en-US"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching stock news: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Parse RSS/XML data
            let parser = StockNewsParser()
            parser.parseNews(data: data) { newsItems in
                DispatchQueue.main.async {
                    if let firstNews = newsItems.first {
                        // Return the most recent headline
                        completion(firstNews.title)
                    } else {
                        // Try alternative: use general market sentiment
                        self.fetchMarketSentiment(for: symbol, completion: completion)
                    }
                }
            }
        }.resume()
    }
    
    private func fetchMarketSentiment(for symbol: String, completion: @escaping (String?) -> Void) {
        // Fallback: Try to get general info from Yahoo Finance quote
        let urlString = "https://query1.finance.yahoo.com/v7/finance/quote?symbols=\(symbol)&fields=longName,marketState,regularMarketChangePercent,fiftyTwoWeekHigh,fiftyTwoWeekLow,regularMarketPrice"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let quoteResponse = json["quoteResponse"] as? [String: Any],
                   let results = quoteResponse["result"] as? [[String: Any]],
                   let quote = results.first {
                    
                    let price = quote["regularMarketPrice"] as? Double ?? 0
                    let high52w = quote["fiftyTwoWeekHigh"] as? Double ?? 0
                    let low52w = quote["fiftyTwoWeekLow"] as? Double ?? 0
                    let changePercent = quote["regularMarketChangePercent"] as? Double ?? 0
                    
                    // Generate insight based on data
                    var insight = ""
                    
                    if price >= high52w * 0.95 {
                        insight = "Trading near 52-week high"
                    } else if price <= low52w * 1.05 {
                        insight = "Trading near 52-week low"
                    } else if abs(changePercent) > 3 {
                        insight = changePercent > 0 ? "Strong bullish momentum today" : "Heavy selling pressure"
                    } else if abs(changePercent) > 1.5 {
                        insight = changePercent > 0 ? "Outperforming the market" : "Underperforming vs peers"
                    } else {
                        insight = "Trading in line with market"
                    }
                    
                    completion(insight)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }.resume()
    }
}

// Simple XML parser for RSS feed
class StockNewsParser: NSObject, XMLParserDelegate {
    private var newsItems: [StockNewsItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var completion: (([StockNewsItem]) -> Void)?
    
    func parseNews(data: Data, completion: @escaping ([StockNewsItem]) -> Void) {
        self.completion = completion
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            currentTitle = ""
            currentLink = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            switch currentElement {
            case "title":
                currentTitle += trimmed
            case "link":
                currentLink += trimmed
            default:
                break
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            let newsItem = StockNewsItem(
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                pubDate: nil,
                source: "Yahoo Finance"
            )
            newsItems.append(newsItem)
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        completion?(newsItems)
    }
}