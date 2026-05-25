// swift-tools-version: 6.2

import PackageDescription

let package = Package(
	name: "AtomicsPerf",
	platforms: [.macOS(.v15)],
	dependencies: [
		.package(
			url: "https://github.com/apple/swift-atomics.git",
			.upToNextMajor(from: "1.3.0")
		)
	],
	targets: [
		.executableTarget(
			name: "AtomicsPerf",
			dependencies: [
				.product(name: "Atomics", package: "swift-atomics")
			]
		),
	],
)
