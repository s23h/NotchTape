import SwiftUI
import LaunchAtLogin
import Defaults

struct Settings: View {
	@Default(.stockSymbols) var stockSymbols
	@Default(.indexSymbols) var indexSymbols
	@State private var newSymbol = ""
	@State private var newIndex = ""
	@FocusState private var isTextFieldFocused: Bool

	var body: some View {
		VStack(spacing: 0) {
			// Header
			HStack {
				Text("Settings")
					.font(.headline)
				Spacer()
				Button(action: {
					AppState.shared.hideCard()
				}) {
					Image(systemSymbol: .xmarkCircleFill)
						.foregroundStyle(.secondary)
						.font(.title2)
				}
				.buttonStyle(.plain)
			}
			.padding()

			Divider()

			// Content
			Form {
				Section {
					LaunchAtLogin.Toggle("Launch at Login")
				}

				Section("Market Indices") {
					ForEach(indexSymbols, id: \.self) { symbol in
						HStack {
							Text(symbol)
								.font(.system(.body, design: .monospaced))
							Spacer()
							Button(action: {
								withAnimation {
									indexSymbols.removeAll { $0 == symbol }
								}
							}) {
								Image(systemSymbol: .minusCircleFill)
									.foregroundStyle(.red)
							}
							.buttonStyle(.plain)
						}
					}

					HStack {
						TextField("Add index (e.g., ^GSPC)...", text: $newIndex)
							.font(.system(.body, design: .monospaced))
							.textFieldStyle(.plain)
							.onSubmit { addIndex() }
						Button(action: { addIndex() }) {
							Image(systemSymbol: .plusCircleFill)
								.foregroundStyle(.green)
						}
						.buttonStyle(.plain)
						.disabled(newIndex.isEmpty)
					}
				}

				Section("Stock Tickers") {
					ForEach(stockSymbols, id: \.self) { symbol in
						HStack {
							Text(symbol)
								.font(.system(.body, design: .monospaced))
							Spacer()
							Button(action: {
								withAnimation {
									stockSymbols.removeAll { $0 == symbol }
								}
							}) {
								Image(systemSymbol: .minusCircleFill)
									.foregroundStyle(.red)
							}
							.buttonStyle(.plain)
						}
					}

					HStack {
						TextField("Add ticker...", text: $newSymbol)
							.font(.system(.body, design: .monospaced))
							.textFieldStyle(.plain)
							.focused($isTextFieldFocused)
							.onSubmit { addSymbol() }
						Button(action: { addSymbol() }) {
							Image(systemSymbol: .plusCircleFill)
								.foregroundStyle(.green)
						}
						.buttonStyle(.plain)
						.disabled(newSymbol.isEmpty)
					}
				}

				Section {
					Button("Reset All to Defaults") {
						indexSymbols = ["^GSPC", "^DJI", "^IXIC", "^VIX"]
						stockSymbols = ["AAPL", "GOOGL", "MSFT", "AMZN", "TSLA", "META", "NVDA", "SPY"]
					}
					.foregroundStyle(.blue)
				}
			}
			.formStyle(.grouped)
		}
		.frame(width: 340, height: 500)
		.onAppear {
			// Activate app and make window key to allow text field focus
			NSApp.activate(ignoringOtherApps: true)
			AppWindow.shared.makeKeyAndOrderFront(nil)
		}
	}

	private func addSymbol() {
		let symbol = newSymbol.uppercased().trimmingCharacters(in: .whitespaces)
		guard !symbol.isEmpty, !stockSymbols.contains(symbol) else {
			newSymbol = ""
			return
		}
		withAnimation {
			stockSymbols.append(symbol)
		}
		newSymbol = ""
	}

	private func addIndex() {
		var symbol = newIndex.uppercased().trimmingCharacters(in: .whitespaces)
		// Auto-add ^ prefix if not present
		if !symbol.hasPrefix("^") {
			symbol = "^" + symbol
		}
		guard !symbol.isEmpty, !indexSymbols.contains(symbol) else {
			newIndex = ""
			return
		}
		withAnimation {
			indexSymbols.append(symbol)
		}
		newIndex = ""
	}
}

#Preview {
	Settings()
}
