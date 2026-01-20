import Foundation
import SwiftUI
import Defaults
import Combine

struct StockQuote: Codable, Identifiable {
    let symbol: String
    let price: Double
    let change: Double
    let changePercent: Double
    let volume: Int?

    var id: String { symbol }

    var changeColor: Color {
        change >= 0 ? .green : .red
    }

    var changeIcon: String {
        change >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
    }

    var formattedPrice: String {
        String(format: "$%.2f", price)
    }

    var formattedChange: String {
        let sign = change >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, changePercent)
    }
}

class StockDataSource: ObservableObject {
    static let shared = StockDataSource()

    @Published var quotes: [StockQuote] = []
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // User-configurable stocks (stored in UserDefaults)
    var symbols: [String] {
        Defaults[.stockSymbols]
    }

    // User-configurable market indices (stored in UserDefaults)
    var indexSymbols: [String] {
        Defaults[.indexSymbols]
    }

    @Published var indices: [StockQuote] = []

    init() {
        fetchStockData()
        startTimer()

        // Observe changes to stock symbols and refresh
        Defaults.publisher(.stockSymbols)
            .sink { [weak self] _ in
                self?.fetchStockData()
            }
            .store(in: &cancellables)

        // Observe changes to index symbols and refresh
        Defaults.publisher(.indexSymbols)
            .sink { [weak self] _ in
                self?.fetchStockData()
            }
            .store(in: &cancellables)
    }

    deinit {
        timer?.invalidate()
        cancellables.removeAll()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.fetchStockData()
        }
    }

    func fetchStockData() {
        // Fetch stocks and indices using v8 chart API
        fetchQuotesV8(symbols: symbols, isIndex: false)
        fetchQuotesV8(symbols: indexSymbols, isIndex: true)
    }

    private func fetchQuotesV8(symbols: [String], isIndex: Bool) {
        let group = DispatchGroup()
        var fetchedQuotes: [StockQuote] = []
        let lock = NSLock()

        for symbol in symbols {
            group.enter()

            // URL encode the symbol (for indices like ^GSPC)
            let encodedSymbol = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
            let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(encodedSymbol)?interval=1d&range=1d"

            guard let url = URL(string: urlString) else {
                group.leave()
                continue
            }

            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", forHTTPHeaderField: "User-Agent")

            URLSession.shared.dataTask(with: request) { data, response, error in
                defer { group.leave() }

                guard let data = data, error == nil else {
                    print("Error fetching \(symbol): \(error?.localizedDescription ?? "Unknown")")
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(YahooChartResponse.self, from: data)

                    if let result = response.chart.result?.first,
                       let meta = result.meta {
                        let price = meta.regularMarketPrice ?? 0
                        let previousClose = meta.chartPreviousClose ?? meta.previousClose ?? price
                        let change = price - previousClose
                        let changePercent = previousClose > 0 ? (change / previousClose) * 100 : 0

                        let quote = StockQuote(
                            symbol: symbol,
                            price: price,
                            change: change,
                            changePercent: changePercent,
                            volume: meta.regularMarketVolume
                        )

                        lock.lock()
                        fetchedQuotes.append(quote)
                        lock.unlock()
                    }
                } catch {
                    print("Error decoding \(symbol): \(error)")
                }
            }.resume()
        }

        group.notify(queue: .main) { [weak self] in
            // Sort to maintain consistent order
            let sortedQuotes = fetchedQuotes.sorted { symbols.firstIndex(of: $0.symbol) ?? 0 < symbols.firstIndex(of: $1.symbol) ?? 0 }

            if sortedQuotes.isEmpty {
                print("⚠️ Using demo stock data due to API error")
                self?.useDemoData()
            } else {
                if isIndex {
                    self?.indices = sortedQuotes
                    print("✅ Fetched \(sortedQuotes.count) market indices")
                } else {
                    self?.quotes = sortedQuotes
                    print("✅ Fetched \(sortedQuotes.count) real stock quotes")
                }
            }
        }
    }

    private func useDemoData() {
        quotes = [
            StockQuote(symbol: "AAPL", price: 235.45, change: 2.34, changePercent: 1.02, volume: 52341234),
            StockQuote(symbol: "GOOGL", price: 178.23, change: -1.45, changePercent: -0.81, volume: 23456789),
            StockQuote(symbol: "MSFT", price: 456.78, change: 5.67, changePercent: 1.26, volume: 34567890),
            StockQuote(symbol: "TSLA", price: 267.89, change: -8.90, changePercent: -3.21, volume: 45678901)
        ]

        indices = [
            StockQuote(symbol: "^GSPC", price: 5823.45, change: 12.34, changePercent: 0.21, volume: nil),
            StockQuote(symbol: "^DJI", price: 42156.78, change: -145.23, changePercent: -0.34, volume: nil),
            StockQuote(symbol: "^IXIC", price: 18234.56, change: 78.90, changePercent: 0.43, volume: nil),
            StockQuote(symbol: "^VIX", price: 15.67, change: 0.45, changePercent: 2.95, volume: nil)
        ]
    }
}

// Yahoo Finance v8 Chart API Response structures
struct YahooChartResponse: Codable {
    let chart: ChartData
}

struct ChartData: Codable {
    let result: [ChartResult]?
    let error: ChartError?
}

struct ChartResult: Codable {
    let meta: ChartMeta?
}

struct ChartMeta: Codable {
    let symbol: String?
    let regularMarketPrice: Double?
    let chartPreviousClose: Double?
    let previousClose: Double?
    let regularMarketVolume: Int?
}

struct ChartError: Codable {
    let code: String?
    let description: String?
}
