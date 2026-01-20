import SwiftUI

// TODO: hide when under menu bar

struct AppView: View {

	@State var size: CGSize = .zero
	var appState = AppState.shared

	var body: some View {

		// App Container

		VStack(spacing: 0) {

			// Notch Bar

			// Temporarily always show the notch bar for testing
			if let notch = NSScreen.builtIn.notch {
				HStack(spacing: notch.width) {
					// TODO: keep widgets within bounds w/ ViewThatFits?

					// Widgets - Left

					HStack {
						WidgetView<AdaptiveTickerPrimary, Never>(primary: AdaptiveTickerPrimary.init)
					}
					.frame(maxWidth: notch.minX + 50, alignment: .leading)

					// Widgets - Right

					HStack(spacing: 8) {
						// Market Overview Widget
						WidgetView<RotatingMarketPrimary, Never>(primary: RotatingMarketPrimary.init)

						// Date/Time Widget
						WidgetView<DateTimePrimary, Never>(primary: DateTimePrimary.init)
					}
					.frame(maxWidth: notch.minX - 50, alignment: .trailing)
				}
				.frame(maxWidth: .infinity, maxHeight: NSScreen.builtIn.notch?.height ?? 31.5)
				.padding(.horizontal)
				.background(.black)
				.environment(\.colorScheme, .dark)
				.zIndex(1) // above window card

				// Top Screen Corners

				Rectangle()
#if DEBUG
					.fill(.red)
#else
					.fill(.black)
#endif
					.frame(height: 10)
					.clipShape(InvertedBottomCorners(radius: 10))
			}

			// Window Card

			Group {
				if let card = appState.card {
					card.view
				}
			}
			.background(.background)
			.roundedCorners(color: .gray.opacity(0.4))
			.modifier(DynamicCardShadow())
			.transition(
				.blurReplace
					.animation(.default)
			)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.padding()
			// TODO: only if inverted top corners
			.padding(.horizontal, 10)
			.padding(.bottom, 10)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
	}
}

struct MenuBarAutoHidePicker: View {
	let option = Binding(get: { SystemState.shared.menuBarAutoHide }, set: { value in
		guard value != SystemState.shared.menuBarAutoHide else { return }
		
		let shellCommand = "defaults write NSGlobalDomain AppleMenuBarVisibleInFullscreen -int"
		shellScript(run: "\(shellCommand) \(value.visibleInFullscreen ? 1 : 0)")

		let scriptCommand = "tell application \"System Events\" to set autohide menu bar of dock preferences to"
		appleScript(run: "\(scriptCommand) \(value.autohideOnDesktop)")
	})

	var body: some View {
		HStack {
			Text("Automatically hide and show the menu bar")
				.frame(maxWidth: .infinity, alignment: .leading)
			Picker("", selection: option) {
				ForEach(MenuBarAutoHide.allCases) { item in
					Text(item.rawValue)
				}
			}
			.fixedSize()
		}
		.padding(.horizontal, 10)
		.frame(width: 458, height: 36)
		.background(.quinary)
		.roundedCorners()
	}
}

#Preview {
	AppView()
}

private struct DynamicCardShadow: ViewModifier {
	@Environment(\.colorScheme) var colorScheme
	func body(content: Content) -> some View {
		if colorScheme == .dark {
			content.shadow(color: .black.opacity(1 - 0.33), radius: 20)
		} else {
			content.shadow(radius: 20)
		}
	}
}
