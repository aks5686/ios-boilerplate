# ios-boilerplate

[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![Platform](https://img.shields.io/badge/iOS-17%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Xcode](https://img.shields.io/badge/Xcode-16%2B-147EFB?logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![CI](https://github.com/aks5686/ios-boilerplate/actions/workflows/ios.yml/badge.svg)](https://github.com/aks5686/ios-boilerplate/actions/workflows/ios.yml)

Production-ready iOS architecture boilerplate built with **Clean Architecture**, **MVVM**, **SwiftUI**, Swift 6 concurrency, and a self-contained design system — no third-party dependencies.

## Getting Started

1. **Create your repo from this template** — click **[Use this template](https://github.com/aks5686/ios-boilerplate/generate)** at the top of the repo (or the green "Use this template" button on GitHub) to create your own repository seeded with this codebase — no fork relationship, no shared history, ready to push to on day one.
2. **Clone it locally**:
   ```bash
   git clone https://github.com/<you>/<your-repo>.git
   cd <your-repo>
   ```
3. **Commit before renaming** — `setup.sh` renames files and folders in place; make sure your working tree is clean (or at least committed) first, so you can diff or roll back easily if anything looks off.
4. **Run the setup script** with your app's name:
   ```bash
   ./setup.sh MyApp
   ```
   This renames every `Boilerplate` reference throughout the project (Xcode project/target, bundle identifier, source files, class names, CI workflow) to `MyApp`. It does not touch this README — update it yourself afterward.
5. **Open the `.xcodeproj` in Xcode and build** — open `MyApp.xcodeproj`, select the `MyApp` scheme, and build/run.

## Features

- **Clean Architecture** — strict separation between Presentation, Domain, and Data layers, with dependencies pointing inward.
- **MVVM** presentation layer using the `@Observable` macro (Swift `Observation` framework), not `ObservableObject`.
- **Swift 6 strict concurrency** — `Sendable` conformances throughout, `async/await` networking, `@MainActor`-isolated view models.
- **Manual dependency injection** via a single composition root (`AppDependencies`), no DI framework required.
- **Secure storage** — session tokens and user data persisted via Keychain Services, never `UserDefaults`.
- **Reusable design system** — centralized color and typography tokens that respect Dynamic Type and Dark Mode.
- **CI/CD** — GitHub Actions pipeline that builds and tests on every push/PR.

## Folder Structure

```
Boilerplate.xcodeproj/
Boilerplate/
├── App/
│   └── AppDependencies.swift        # Composition root / manual DI container
├── BoilerplateApp.swift             # @main App entry point
├── ContentView.swift                # Root view
│
├── Core/                            # Cross-feature infrastructure
│   ├── Network/
│   │   ├── NetworkClient.swift      # async/await URLSession wrapper + Endpoint protocol
│   │   └── APIError.swift           # Localized network error type
│   ├── Storage/
│   │   └── KeychainManager.swift    # Secure Keychain read/write/delete
│   └── Extensions/
│       ├── View+Extensions.swift
│       └── String+Extensions.swift
│
├── DesignSystem/                    # App-wide visual tokens
│   ├── Colors/AppColors.swift
│   └── Typography/AppFonts.swift
│
├── Features/                        # One folder per feature, each with its own layers
│   └── Auth/
│       ├── Domain/
│       │   ├── AuthUseCaseProtocol.swift   # Business logic contract + domain models
│       │   └── AuthUseCase.swift           # Business logic implementation
│       ├── Data/
│       │   └── AuthRepository.swift        # Network + Keychain-backed data source
│       └── Presentation/
│           ├── LoginViewModel.swift        # @Observable view model
│           └── LoginView.swift             # SwiftUI screen
│
└── Assets.xcassets/

BoilerplateTests/                    # Unit tests (Swift Testing)
BoilerplateUITests/                  # UI tests
```

The Xcode project uses **synchronized file system groups** (Xcode 16+), so any file or folder added under `Boilerplate/` on disk is automatically picked up by the target — there's no `.pbxproj` bookkeeping when adding a new feature file.

## Architecture

Each feature is a vertical slice through three layers, with dependencies flowing **Presentation → Domain → Data**, never the reverse:

| Layer | Responsibility | Depends on |
|---|---|---|
| **Presentation** | SwiftUI views + `@Observable` view models. Owns UI state, delegates all logic to a use case. | Domain (protocol only) |
| **Domain** | Business rules and validation, expressed as a `UseCaseProtocol` + models. Has no knowledge of networking or storage. | Repository protocol only |
| **Data** | Repository implementations that talk to `NetworkClient`, `KeychainManager`, or other data sources, and map DTOs to domain models. | Core services |

Every cross-layer boundary is a **protocol** (`AuthUseCaseProtocol`, `AuthRepositoryProtocol`, `NetworkClientProtocol`), so each layer can be tested in isolation with a fake/mock conforming to the protocol — no live network or Keychain access required in unit tests.

`AppDependencies` (`App/AppDependencies.swift`) is the single **composition root**: it lazily constructs every concrete dependency and wires them together, then exposes `make...ViewModel()` factory methods. Views ask the container for a fully-formed view model instead of constructing dependencies themselves.

## Adding a New Feature

1. Create `Features/<FeatureName>/{Domain,Data,Presentation}`.
2. **Domain**: define `<Feature>UseCaseProtocol` (+ any domain models/errors) and a concrete `<Feature>UseCase`.
3. **Data**: define `<Feature>RepositoryProtocol` + a concrete repository that talks to `NetworkClient`/`KeychainManager`, plus any `Endpoint` cases and DTOs it needs.
4. **Presentation**: an `@Observable` `@MainActor` view model, and a SwiftUI view that reads it via `AppColors`/`AppFonts`.
5. Wire it up in `AppDependencies`: add lazy `repository`/`useCase` properties and a `make<Feature>ViewModel()` factory.

## Networking

`NetworkClient` (`Core/Network/NetworkClient.swift`) is a thin, protocol-oriented wrapper over `URLSession`:

```swift
enum SomeEndpoint: Endpoint {
    var baseURL: String { AppEnvironment.current.baseURL }
    var path: String { "/some/path" }
    var method: HTTPMethod { .get }
}

let result: SomeResponse = try await networkClient.request(SomeEndpoint())
```

Failures surface as typed `APIError` cases (`.unauthorized`, `.notFound`, `.serverError`, `.noInternetConnection`, …), each with a localized `errorDescription` and `recoverySuggestion` ready to show in `View.errorAlert(error:)`.

## Secure Storage

`KeychainManager` (`Core/Storage/KeychainManager.swift`) stores raw `Data`, `String`, or any `Codable` value, scoped to a `service` identifier (defaults to the app's bundle ID):

```swift
try keychainManager.save(user, for: "current_user")
let user: User = try keychainManager.retrieve(for: "current_user", as: User.self)
try keychainManager.delete(for: "current_user")
```

## Design System

`AppColors` and `AppFonts` (`DesignSystem/`) are the only place UI code should reach for raw colors or fonts. Colors are defined as light/dark pairs (no asset catalog entries required) and fonts are built on Dynamic Type text styles, so both dark mode and accessibility text sizes work automatically.

## Requirements

- Xcode 16+
- Swift 6 language mode (`SWIFT_VERSION = 6.0`)
- iOS 17+ (for the `Observation` framework's `@Observable` macro)

## Running Tests

```bash
xcodebuild test \
  -project Boilerplate.xcodeproj \
  -scheme Boilerplate \
  -destination 'generic/platform=iOS Simulator'
```

## CI/CD

`.github/workflows/ios.yml` runs on every push/PR to `main`:

- **build-and-test** — builds the app and runs the unit/UI test targets on an iOS Simulator, uploading the `.xcresult` bundle as an artifact.
- **lint** — runs SwiftLint (non-blocking; add a `.swiftlint.yml` to customize rules).

## License

See [LICENSE](LICENSE).
