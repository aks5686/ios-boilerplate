//
//  KeychainManager.swift
//  Boilerplate
//
//  Created by Ayush Kumar Sethi on 27/07/26.
//

import Foundation
import Security

/// Secure, `Codable`-friendly wrapper around Keychain Services.
///
/// All values are stored as generic passwords scoped to `service`, so multiple
/// keychain-backed apps/extensions sharing a device won't collide on the same key.
final class KeychainManager: Sendable {

    enum KeychainError: LocalizedError, Equatable {
        case itemNotFound
        case duplicateItem
        case invalidData
        case unexpectedStatus(OSStatus)

        var errorDescription: String? {
            switch self {
            case .itemNotFound:
                return "The requested item was not found in the keychain."
            case .duplicateItem:
                return "The item already exists in the keychain."
            case .invalidData:
                return "The data could not be encoded or decoded."
            case .unexpectedStatus(let status):
                return "Unexpected keychain error (status \(status))."
            }
        }
    }

    private let service: String
    private let accessGroup: String?

    init(
        service: String = Bundle.main.bundleIdentifier ?? "com.boilerplate.app",
        accessGroup: String? = nil
    ) {
        self.service = service
        self.accessGroup = accessGroup
    }

    // MARK: - Save

    func save(_ data: Data, for key: String) throws {
        var query = baseQuery(for: key)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        // Remove any existing item first so `save` behaves as an upsert.
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func save(_ string: String, for key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try save(data, for: key)
    }

    func save<T: Encodable>(_ value: T, for key: String) throws {
        do {
            let data = try JSONEncoder().encode(value)
            try save(data, for: key)
        } catch let error as KeychainError {
            throw error
        } catch {
            throw KeychainError.invalidData
        }
    }

    // MARK: - Retrieve

    func retrieve(for key: String) throws -> Data {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            throw status == errSecItemNotFound
                ? KeychainError.itemNotFound
                : KeychainError.unexpectedStatus(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }

        return data
    }

    func retrieveString(for key: String) throws -> String {
        let data = try retrieve(for: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return string
    }

    func retrieve<T: Decodable>(for key: String, as type: T.Type) throws -> T {
        let data = try retrieve(for: key)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw KeychainError.invalidData
        }
    }

    // MARK: - Delete

    func delete(for key: String) throws {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Deletes every item this manager has stored under its `service`.
    func clearAll() throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - Private

    private func baseQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }
}
