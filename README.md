# ios-boilerplate

[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-000000?logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![Platform](https://img.shields.io/badge/iOS-17%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Xcode](https://img.shields.io/badge/Xcode-16%2B-147EFB?logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![CI](https://github.com/aks5686/ios-boilerplate/actions/workflows/ios.yml/badge.svg)](https://github.com/aks5686/ios-boilerplate/actions/workflows/ios.yml)

Production-ready iOS boilerplate with Clean Architecture, MVVM, SwiftUI, Swift 6 concurrency and GitHub Actions CI/CD.

## Getting Started

1. Click **[Use this template](https://github.com/aks5686/ios-boilerplate/generate)** on GitHub.
2. Clone your repo locally:
   ```bash
   git clone https://github.com/<you>/<your-repo>.git
   cd <your-repo>
   ```
3. Run:
   ```bash
   ./setup.sh YourAppName
   ```
4. Open the `.xcodeproj` in Xcode and build.

## Architecture

Each feature is a vertical slice through three layers, with dependencies flowing **Presentation → Domain → Data**, never the reverse:

| Layer | Responsibility | Depends on |
|---|---|---|
| **Presentation** | SwiftUI views + `@Observable` view models. Owns UI state, delegates all logic to a use case. | Domain (protocol only) |
| **Domain** | Business rules and validation, expressed as a `UseCaseProtocol` + models. Has no knowledge of networking or storage. | Repository protocol only |
| **Data** | Repository implementations that talk to `NetworkClient`, `KeychainManager`, or other data sources, and map DTOs to domain models. | Core services |

Every cross-layer boundary is a **protocol** (`AuthUseCaseProtocol`, `AuthRepositoryProtocol`, `NetworkClientProtocol`), so each layer can be tested in isolation with a fake/mock conforming to the protocol — no live network or Keychain access required in unit tests.

`AppDependencies` (`App/AppDependencies.swift`) is the single **composition root**: it lazily constructs every concrete dependency and wires them together, then exposes `make...ViewModel()` factory methods. Views ask the container for a fully-formed view model instead of constructing dependencies themselves.

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

## Features

- **Clean Architecture** — strict separation between Presentation, Domain, and Data layers, with dependencies pointing inward.
- **MVVM** presentation layer using the `@Observable` macro (Swift `Observation` framework), not `ObservableObject`.
- **Swift 6 strict concurrency** — `Sendable` conformances throughout, `async/await` networking, `@MainActor`-isolated view models.
- **Manual dependency injection** via a single composition root (`AppDependencies`), no DI framework required.
- **Secure storage** — session tokens and user data persisted via Keychain Services, never `UserDefaults`.
- **Reusable design system** — centralized color and typography tokens that respect Dynamic Type and Dark Mode.
- **CI/CD** — GitHub Actions pipeline that builds and tests on every push/PR.

## Usage Guide

### Adding a new feature

Follow the same vertical-slice pattern as `Features/Auth`, working outside-in:

1. **Domain** — define a `<Feature>UseCaseProtocol` with the business methods your feature needs, plus any plain domain models. Implement it in `<Feature>UseCase`, depending only on a repository protocol.
2. **Data** — define `<Feature>RepositoryProtocol` and implement `<Feature>Repository`, using `NetworkClientProtocol` and/or `KeychainManager` to fetch and persist data, mapping DTOs to domain models.
3. **Presentation** — build an `@Observable` `<Feature>ViewModel` that calls the use case and exposes UI state, and a SwiftUI `<Feature>View` that binds to it.
4. **Wire it in** — add a `make<Feature>ViewModel()` factory to `AppDependencies` (`App/AppDependencies.swift`) that constructs the repository, use case, and view model in order. Views should only ever ask `AppDependencies` for a ready-made view model, never construct one themselves.

Because the Xcode project uses synchronized file system groups, just add the new `Features/<Feature>/{Domain,Data,Presentation}` folders and files on disk — no `.pbxproj` editing required.

### Networking

`NetworkClient` (`Core/Network/NetworkClient.swift`) is a protocol-oriented, async/await wrapper around `URLSession`. To call an API:

1. Define an `enum` conforming to `Endpoint` for your feature (see `AuthEndpoint`), providing `baseURL`, `path`, `method`, and optionally `headers`, `body`, and `queryItems`.
2. Inject `NetworkClientProtocol` into your repository (via `AppDependencies`) and call one of:
   ```swift
   let user: User = try await networkClient.request(AuthEndpoint.profile)
   try await networkClient.request(AuthEndpoint.logout)  // no response body
   ```
3. Failures surface as `APIError`, and responses are decoded with `JSONDecoder.boilerplateDefault` (snake_case keys, ISO 8601 dates).

Depend on `NetworkClientProtocol`, not the concrete `NetworkClient`, so repositories can be unit tested with a mock/fake implementation.

### Secure Storage

`KeychainManager` (`Core/Storage/KeychainManager.swift`) wraps Keychain Services for storing sensitive data (session tokens, credentials) — never use `UserDefaults` for this.

```swift
let keychain = KeychainManager()

try keychain.save("token-value", for: "authToken")          // String
try keychain.save(someCodableModel, for: "userProfile")      // Codable
let token = try keychain.retrieveString(for: "authToken")
let profile: UserProfile = try keychain.retrieve(for: "userProfile", as: UserProfile.self)
try keychain.delete(for: "authToken")
try keychain.clearAll()                                      // e.g. on logout
```

All read/write/delete operations throw `KeychainManager.KeychainError`, so wrap calls in `do/catch` or propagate them up through your repository/use case layers.

### Testing

Unit tests use **Swift Testing** (`BoilerplateTests`) and UI tests use XCTest (`BoilerplateUITests`). Run them from the command line with:

```bash
xcodebuild test \
  -project Boilerplate.xcodeproj \
  -scheme Boilerplate \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Because every cross-layer boundary is a protocol, use cases and repositories can be tested with fake implementations (no live network or Keychain access needed) — see how `AuthUseCase` and `AuthRepository` are tested for the pattern to follow in new features.

## CI/CD

`.github/workflows/ios.yml` runs on every push/PR to `main`:

- **build-and-test** — builds the app and runs the unit/UI test targets on an iOS Simulator, uploading the `.xcresult` bundle as an artifact.
- **lint** — runs SwiftLint (non-blocking; add a `.swiftlint.yml` to customize rules).

## License

See [LICENSE](LICENSE).
