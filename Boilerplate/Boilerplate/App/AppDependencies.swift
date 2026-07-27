//
//  AppDependencies.swift
//  Boilerplate
//
//  Created by Ayush Kumar Sethi on 27/07/26.
//

import Foundation

/// Manual dependency injection container following Clean Architecture principles.
///
/// `AppDependencies` composes concrete implementations of every layer (Core services,
/// repositories, use cases) and exposes factory methods for view models. Views never
/// construct their dependencies directly — they receive them from this container,
/// which keeps the dependency graph in one place and makes it easy to swap
/// implementations (e.g. for previews or tests) without touching feature code.
@MainActor
final class AppDependencies {

    // MARK: - Singleton

    static let shared = AppDependencies()

    // MARK: - Core Dependencies

    private(set) lazy var networkClient: NetworkClientProtocol = {
        NetworkClient()
    }()

    private(set) lazy var keychainManager: KeychainManager = {
        KeychainManager()
    }()

    // MARK: - Feature Dependencies (Auth)

    private(set) lazy var authRepository: AuthRepositoryProtocol = {
        AuthRepository(networkClient: networkClient, keychainManager: keychainManager)
    }()

    private(set) lazy var authUseCase: AuthUseCaseProtocol = {
        AuthUseCase(repository: authRepository)
    }()

    // MARK: - ViewModel Factories

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(authUseCase: authUseCase)
    }

    // MARK: - Init

    private init() {}

    // MARK: - Testing Support

    /// Resets all lazily-created dependencies. Intended for use in unit tests / previews
    /// where a clean dependency graph is required between runs.
    func reset() {
        authRepository = AuthRepository(networkClient: networkClient, keychainManager: keychainManager)
        authUseCase = AuthUseCase(repository: authRepository)
    }
}
