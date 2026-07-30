//
//  APIError.swift
//  Boilerplate
//
//  Created by Ayush Kumar Sethi on 27/07/26.
//

import Foundation

/// Custom error type surfaced by ``NetworkClient`` for all networking failures.
///
/// Conforms to `LocalizedError` so callers can present `errorDescription` /
/// `recoverySuggestion` directly to the user without any translation layer.
enum APIError: LocalizedError, Sendable, Equatable {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(String)
    case networkError(String)
    case unauthorized
    case forbidden
    case notFound
    case serverError
    case noInternetConnection
    case timeout
    case cancelled
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid."
        case .invalidResponse:
            return "The server response was invalid."
        case .httpError(let statusCode):
            return "The server returned an error (status code \(statusCode))."
        case .decodingError(let message):
            return "Failed to decode the response: \(message)"
        case .networkError(let message):
            return "A network error occurred: \(message)"
        case .unauthorized:
            return "You are not authorized to perform this action."
        case .forbidden:
            return "You don't have permission to access this resource."
        case .notFound:
            return "The requested resource could not be found."
        case .serverError:
            return "A server error occurred. Please try again later."
        case .noInternetConnection:
            return "No internet connection. Please check your network settings."
        case .timeout:
            return "The request timed out. Please try again."
        case .cancelled:
            return "The request was cancelled."
        case .unknown:
            return "An unknown error occurred."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .unauthorized:
            return "Please log in again."
        case .forbidden:
            return "Contact support if you believe this is a mistake."
        case .noInternetConnection:
            return "Check your Wi-Fi or cellular connection and try again."
        case .timeout, .networkError:
            return "Please check your internet connection and try again."
        case .serverError:
            return "Please try again later."
        case .httpError(let statusCode) where statusCode >= 500:
            return "The server is experiencing issues. Please try again later."
        default:
            return "Please try again."
        }
    }

    /// Maps a raw HTTP status code to the most specific ``APIError`` case.
    static func from(statusCode: Int) -> APIError {
        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 500...599:
            return .serverError
        default:
            return .httpError(statusCode: statusCode)
        }
    }

    /// Maps a system-level `URLError` / arbitrary `Error` into an ``APIError``.
    static func from(_ error: Error) -> APIError {
        if let apiError = error as? APIError {
            return apiError
        }

        let urlError = error as? URLError
        switch urlError?.code {
        case .notConnectedToInternet:
            return .noInternetConnection
        case .timedOut:
            return .timeout
        case .cancelled:
            return .cancelled
        default:
            return .networkError(error.localizedDescription)
        }
    }
}
