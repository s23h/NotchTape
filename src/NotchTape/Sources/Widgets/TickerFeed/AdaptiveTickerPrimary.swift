import SwiftUI
import SFSafeSymbols
import AppKit

struct AdaptiveTickerPrimary: View {
    @State private var data = TickerFeedData()
    @State private var currentIndex = 0
    @State private var isAnimating = false
    @Binding var expand: Bool
    
    let timer = Timer.publish(every: 6, on: .main, in: .common).autoconnect() // Comfortable reading speed
    
    var currentItems: [TickerFeedData.FeedItem] {
        guard !data.items.isEmpty else { return [] }
        let startIndex = currentIndex % data.items.count
        
        // Check if current item is a news item (typically longer)
        let currentItem = data.items[startIndex]
        
        if currentItem.type == .news {
            // Show only one news item as it's longer
            return [currentItem]
        } else {
            // Show 2 shorter items (stocks, notifications)
            var items = [currentItem]
            var nextIndex = (startIndex + 1) % data.items.count
            
            if nextIndex != startIndex {
                let nextItem = data.items[nextIndex]
                if nextItem.type != .news {
                    items.append(nextItem)
                }
            }
            
            return items
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if currentItems.isEmpty {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 12, height: 12)
                    Text("Loading market data...")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 16) {
                    ForEach(currentItems) { item in
                        Button(action: {
                            handleItemClick(item)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: item.type.icon)
                                    .foregroundStyle(item.type.color.gradient)
                                    .font(.system(size: 12))
                                
                                Text(item.text)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(maxWidth: item.type == .news ? .infinity : nil)
                            }
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            if hovering && item.url != nil {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        
                        if item.id != currentItems.last?.id {
                            Divider()
                                .frame(height: 14)
                                .opacity(0.3)
                        }
                    }
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
            // Skip ahead based on how many items we showed
            let itemsShown = currentItems.count
            currentIndex += itemsShown
            
            withAnimation(.easeOut(duration: 0.3)) {
                isAnimating = false
            }
        }
    }
    
    private func handleItemClick(_ item: TickerFeedData.FeedItem) {
        guard let urlString = item.url,
              let url = URL(string: urlString) else { return }
        
        // Open the URL
        NSWorkspace.shared.open(url)
        
        // Mark as read
        ReadHistoryManager.shared.markAsRead(urlString)
        
        // Remove from current rotation
        if let index = data.items.firstIndex(where: { $0.id == item.id }) {
            data.items.remove(at: index)
        }
        
        // Force immediate rotation to next item
        rotateToNext()
    }
}