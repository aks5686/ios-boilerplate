//
//  AuthRepository.swift
//  Boilerplate
//
//  Created by Ayush Kumar Sethi on 27/07/26.
//

import Foundation

// MARK: - Repository Protocol

/// Data-layer abstraction for authentication. Hides whether a given operation is
/// served from the network, the Keychain, or a combination of both.
protocol AuthRepositoryProtocol: Sendable {
    func login(email: String, password: String) async throws -> User
    func logout() async throws
    func getCurrentUser() async throws -> User?
    func isAuthenticated() async -> Bool
}

// MARK: - Repository Implementation

/// Concrete auth repository backed by ``NetworkClient`` for remote calls and
/// ``KeychainManager`` for persisting the session locally.
final class AuthRepository: AuthRepositoryProtocol, Sendable {

    private let networkClient: NetworkClientProtocol
    private let keychainManager: KeychainManager

    private enum StorageKey {
        static let token = "auth_token"
        static let user = "current_user"
    }

    init(networkClient: NetworkClientProtocol, keychainManager: KeychainManager) {
        self.networkClient = networkClient
        self.keychainManager = keychainManager
    }

    func login(email: String, password: String) async throws -> User {
        let endpoint = AuthEndpoint.login(email: email, password: password)
        let response: LoginResponse = try await networkClient.request(endpoint)

        try keychainManager.save(response.token, for: StorageKey.token)
        try keychainManager.save(response.user, for: StorageKey.user)

        return response.user
    }

    func logout() async throws {
        // Best-effort remote invalidation — local state is cleared either way.
        try? await networkClient.request(AuthEndpoint.logout)

        try keychainManager.delete(for: StorageKey.token)
        try keychainManager.delete(for: StorageKey.user)
    }

    func getCurrentUser() async throws -> User? {
        do {
            return try keychainManager.retrieve(for: StorageKey.user, as: User.self)
        } catch KeychainManager.KeychainError.itemNotFound {
            return nil
        }
    }

    func isAuthenticated() async -> Bool {
        (try? keychainManager.retrieve(for: StorageKey.token, as: AuthToken.self)) != nil
    }
}

// MARK: - Endpoints

enum AuthEndpoint: Endpoint {
    case login(email: String, password: String)
    case logout

    var baseURL: String {
        AppEnvironment.current.baseURL
    }

    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .logout:
            return "/auth/logout"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .logout:
            return .post
        }
    }

    var body: Data? {
        switch self {
        case .login(let email, let password):
            let payload = LoginRequest(email: email, password: password)
            return try? JSONEncoder().encode(payload)
        case .logout:
            return nil
        }
    }
}

// MARK: - Data Transfer Objects

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct LoginResponse: Decodable {
    let user: User
    let token: AuthToken
}

// MARK: - Environment

/// The set of backend environments the app can target. Replace `baseURL` values with
/// your real endpoints, and switch `current` per build configuration/scheme as needed.
enum AppEnvironment {
    case development
    case staging
    case production

    var baseURL: String {
        switch self {
        case .development:
            return "https://dev.api.example.com"
        case .staging:
            return "https://staging.api.example.com"
        case .production:
            return "https://api.example.com"
        }
    }

    static let current: AppEnvironment = {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }()
}
