import SwiftUI
import SFSafeSymbols

struct RotatingTickerPrimary: View {
    @State private var data = TickerFeedData()
    @State private var currentIndex = 0
    @State private var isAnimating = false
    @Binding var expand: Bool
    
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var currentItem: TickerFeedData.FeedItem? {
        guard !data.items.isEmpty else { return nil }
        return data.items[currentIndex % data.items.count]
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Static icon
            Image(systemSymbol: .antennaRadiowavesLeftAndRight)
                .foregroundStyle(.purple.gradient)
                .font(.system(size: 14))
            
            // Rotating content
            if let item = currentItem {
                HStack(spacing: 8) {
                    Image(systemName: item.type.icon)
                        .foregroundStyle(item.type.color.gradient)
                        .font(.system(size: 12))
                    
                    Text(item.text)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .rotation3DEffect(
                    .degrees(isAnimating ? -90 : 0),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .center,
                    anchorZ: 0,
                    perspective: 0.5
                )
                .opacity(isAnimating ? 0 : 1)
                .animation(.easeInOut(duration: 0.4), value: isAnimating)
            } else {
                Text("Loading feed...")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .opacity(0.3)
        )
        .onReceive(timer) { _ in
            rotateToNext()
        }
    }
    
    private func rotateToNext() {
        guard !data.items.isEmpty else { return }
        
        withAnimation(.easeIn(duration: 0.3)) {
            isAnimating = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentIndex += 1
            
            withAnimation(.easeOut(duration: 0.3)) {
                isAnimating = false
            }
        }
    }
}