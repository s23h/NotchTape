import SwiftUI
import SFSafeSymbols

struct TickerFeedPrimary: View {
    @State private var data = TickerFeedData()
    @State private var isPaused = false
    @Binding var expand: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemSymbol: .antennaRadiowavesLeftAndRight)
                .foregroundStyle(.purple.gradient)
                .font(.system(size: 14))
            
            if data.items.isEmpty {
                Text("No feed items")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))
            } else {
                Marquee(targetVelocity: isPaused ? 0 : 50, spacing: 40) {
                    ForEach(data.items) { item in
                        HStack(spacing: 6) {
                            Image(systemName: item.type.icon)
                                .foregroundStyle(item.type.color.gradient)
                                .font(.system(size: 11))
                            
                            Text(item.text)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .frame(maxWidth: 300)
                .onHover { hovering in
                    isPaused = hovering
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        )
    }
}