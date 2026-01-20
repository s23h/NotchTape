import SwiftUI
import SFSafeSymbols
import AppKit

struct RotatingMarketPrimary: View {
    @StateObject private var stockData = StockDataSource.shared
    @State private var currentPage = 0
    @State private var isAnimating = false
    @State private var showingStockDetail: StockQuote? = nil
    @State private var stockNews: String = ""
    @Binding var expand: Bool

    let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    let itemsPerPage = 4

    // All items: indices first, then stocks
    var allItems: [StockQuote] {
        stockData.indices + stockData.quotes
    }

    var totalPages: Int {
        max(1, (allItems.count + itemsPerPage - 1) / itemsPerPage)
    }

    var currentItems: [StockQuote] {
        let startIndex = currentPage * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, allItems.count)
        guard startIndex < allItems.count else { return [] }
        return Array(allItems[startIndex..<endIndex])
    }

    var isShowingIndices: Bool {
        currentPage == 0 && !stockData.indices.isEmpty
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if let detailStock = showingStockDetail {
                // Focused stock view
                HStack(spacing: 12) {
                    // Stock info
                    HStack(spacing: 3) {
                        Text(detailStock.symbol)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        Text(detailStock.formattedPrice)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                        
                        Text(detailStock.formattedChange)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(detailStock.changeColor)
                    }
                    
                    Divider()
                        .frame(height: 14)
                        .opacity(0.3)
                    
                    // News
                    Text(stockNews.isEmpty ? "Loading news..." : stockNews)
                        .font(.system(size: 11))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingStockDetail = nil
                            stockNews = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.9)),
                    removal: .opacity
                ))
            } else {
                // Normal rotating view
                HStack(spacing: 10) {
                    ForEach(currentItems) { stock in
                        Button(action: { 
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingStockDetail = stock
                                fetchStockNews(for: stock)
                            }
                        }) {
                            HStack(spacing: 3) {
                                Text(stock.symbol.hasPrefix("^") ? stock.symbol.dropFirst().prefix(4).uppercased() : stock.symbol)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)

                                Text(stock.symbol.hasPrefix("^") ?
                                     String(format: "%.0f", stock.price) :
                                     stock.formattedPrice)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .monospacedDigit()
                                    .lineLimit(1)

                                Text(stock.formattedChange)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(stock.changeColor)
                                    .lineLimit(1)
                            }
                            .fixedSize()
                        }
                        .buttonStyle(.plain)
                        
                        if stock.id != currentItems.last?.id {
                            Divider()
                                .frame(height: 12)
                                .opacity(0.3)
                        }
                    }
                }
                .frame(minWidth: 200)
                .rotation3DEffect(
                    .degrees(isAnimating ? -90 : 0),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .center,
                    anchorZ: 0,
                    perspective: 0.5
                )
                .opacity(isAnimating ? 0 : 1)
                .animation(.easeInOut(duration: 0.4), value: isAnimating)
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity.combined(with: .scale(scale: 0.9))
                ))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.ultraThinMaterial)
                .opacity(0.2)
        )
        .onReceive(timer) { _ in
            if showingStockDetail == nil {
                rotateDisplay()
            }
        }
    }
    
    private func rotateDisplay() {
        withAnimation(.easeIn(duration: 0.3)) {
            isAnimating = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Move to next page, wrap around
            currentPage = (currentPage + 1) % totalPages

            withAnimation(.easeOut(duration: 0.3)) {
                isAnimating = false
            }
        }
    }
    
    private func fetchStockNews(for stock: StockQuote) {
        // Show loading state
        stockNews = "Fetching latest news..."
        
        // Fetch real news
        StockNewsDataSource.shared.fetchNews(for: stock.symbol) { newsHeadline in
            if let headline = newsHeadline {
                self.stockNews = headline
            } else {
                // Fallback to basic insight if no news available
                if stock.change > 0 {
                    self.stockNews = "Up \(stock.formattedChange) - No recent news available"
                } else {
                    self.stockNews = "Down \(stock.formattedChange) - No recent news available"
                }
            }
        }
    }
}