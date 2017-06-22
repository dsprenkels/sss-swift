// swift-tools-version:3.1

import PackageDescription

let package = Package(
	name: "ShamirSecretSharing",
	targets: [
		Target(name: "ShamirSecretSharing", dependencies: ["libsss"])
	]
)
