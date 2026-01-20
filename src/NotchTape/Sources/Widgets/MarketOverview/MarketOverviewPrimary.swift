import SwiftUI
import SFSafeSymbols

struct MarketOverviewPrimary: View {
    @StateObject private var stockData = StockDataSource.shared
    @Binding var expand: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            if stockData.indices.isEmpty {
                Text("Loading markets...")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(stockData.indices.prefix(3)) { index in
                MarketIndexView(index: index)
                
                if index.id != stockData.indices.prefix(3).last?.id {
                    Divider()
                        .frame(height: 12)
                        .opacity(0.3)
                }
            }
            
                // VIX as special indicator
                if let vix = stockData.indices.first(where: { $0.symbol == "^VIX" }) {
                    Divider()
                        .frame(height: 12)
                        .opacity(0.3)
                    
                    VIXIndicator(vix: vix)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.ultraThinMaterial)
                .opacity(0.2)
        )
    }
}

struct MarketIndexView: View {
    let index: StockQuote
    
    var displayName: String {
        switch index.symbol {
        case "^GSPC": return "S&P"
        case "^DJI": return "DOW"
        case "^IXIC": return "NAS"
        default: return index.symbol
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            
            Text(String(format: "%.0f", index.price))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
            
            HStack(spacing: 1) {
                Image(systemName: index.changeIcon)
                    .font(.system(size: 8))
                Text(index.formattedChange)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(index.changeColor)
        }
    }
}

struct VIXIndicator: View {
    let vix: StockQuote
    
    var fearLevel: (String, Color) {
        switch vix.price {
        case 0..<12: return ("Low", .green)
        case 12..<20: return ("Normal", .blue)
        case 20..<30: return ("High", .orange)
        default: return ("Extreme", .red)
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text("VIX")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            
            Text(String(format: "%.1f", vix.price))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
            
            Text("(\(fearLevel.0))")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(fearLevel.1)
        }
    }
}