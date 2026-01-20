import SwiftUI

struct DateTimePrimary: View {
    @Binding var expand: Bool

    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM"
        return formatter
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(dateFormatter.string(from: currentTime))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            Text(timeFormatter.string(from: currentTime))
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(.fill)
        .clipShape(.capsule(style: .continuous))
        .padding(.bottom, 2)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

#Preview {
    @Previewable @State var expand = false
    DateTimePrimary(expand: $expand)
}
