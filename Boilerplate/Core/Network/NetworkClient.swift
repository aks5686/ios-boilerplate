//
//  NetworkClient.swift
//  Boilerplate
//
//  Created by Ayush Kumar Sethi on 27/07/26.
//

import Foundation

/// Protocol-oriented, async/await network client.
///
/// Abstracted behind a protocol so repositories can be unit tested against a mock
/// without touching the network.
protocol NetworkClientProtocol: Sendable {
    /// Performs a request and decodes the response body into `T`.
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    /// Performs a request that returns no meaningful response body.
    func request(_ endpoint: Endpoint) async throws
}

/// Concrete `URLSession`-backed implementation of ``NetworkClientProtocol``.
final class NetworkClient: NetworkClientProtocol, Sendable {

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = .boilerplateDefault) {
        self.session = session
        self.decoder = decoder
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await performRequest(endpoint)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    func request(_ endpoint: Endpoint) async throws {
        _ = try await performRequest(endpoint)
    }

    // MARK: - Private

    private func performRequest(_ endpoint: Endpoint) async throws -> Data {
        let request = try endpoint.asURLRequest()

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.from(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.from(statusCode: httpResponse.statusCode)
        }

        return data
    }
}

// MARK: - Endpoint

/// Describes a single network endpoint. Feature modules define their own
/// `Endpoint`-conforming enums (see `AuthEndpoint`) to keep request construction
/// close to the feature that owns it.
protocol Endpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
    var queryItems: [URLQueryItem]? { get }
}

extension Endpoint {

    var headers: [String: String]? { nil }
    var queryItems: [URLQueryItem]? { nil }
    var body: Data? { nil }

    func asURLRequest() throws -> URLRequest {
        guard var components = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - JSONDecoder

extension JSONDecoder {
    /// Shared decoder configuration used across the app's network layer.
    static let boilerplateDefault: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
