import ProjectDescription

let project = Project(
	name: "NotchTape",
	settings: .settings(base: [
		"ENABLE_USER_SCRIPT_SANDBOXING": .init(booleanLiteral: true),
		"ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": .init(booleanLiteral: true),
	]),
	targets: [
		.target(
			name: "NotchTape",
			destinations: .macOS,
			product: .app,
			bundleId: "com.s23h.notchtape",
			deploymentTargets: .macOS("14.6.1"),
			infoPlist: .extendingDefault(with: [
				"LSUIElement": true,
				"LSApplicationCategoryType": "public.app-category.productivity",
				"CFBundleShortVersionString": "0.0.1", // Public
				"CFBundleVersion": "1", // Internal
				"CFBundleURLTypes": .array([
					.dictionary([
						"CFBundleURLName": .string("com.s23h.notchtape"),
						"CFBundleURLSchemes": .array(["notchtape"]),
						"CFBundleTypeRole": .string("Viewer"),
					]),
				]),
				"NSAppleEventsUsageDescription": "Auto-Hide Menu Bar",
			]),
			sources: ["NotchTape/Sources/**"],
			resources: ["NotchTape/Resources/**"],
			entitlements: .dictionary([
				"com.apple.security.automation.apple-events": .string("YES"),
			]),
			dependencies: [
				.external(name: "SFSafeSymbols"),
				.external(name: "LaunchAtLogin"),
				.external(name: "Pow"),
				.external(name: "SystemInfoKit"),
				.external(name: "Defaults"),
			]
		),
	]
)
