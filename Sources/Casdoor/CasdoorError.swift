// Copyright 2021 The casbin Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

public struct CasdoorError: Swift.Error, CustomStringConvertible, LocalizedError, Sendable {
    public enum Kind: Equatable, Sendable {
        /// A URL built from the config is malformed, check `endpoint` and `apiEndpoint`.
        case invalidURL
        /// Casdoor API returned `{"status": "error", "msg": ...}`.
        case responseMessage(String)
        /// OAuth endpoint returned `{"error": ..., "error_description": ...}`.
        case oauth(error: String, description: String?)
        /// The server answered with something that is not the expected JSON,
        /// for example an HTML 404 page when `endpoint` points to the wrong host.
        case invalidResponse(statusCode: Int, body: String)
        case invalidJwt(String)
        /// The redirect URL passed to `handleCallback(url:)` has no code or a wrong state.
        case invalidCallback(String)
        /// `requestOauthAccessToken` was called before `getSigninUrl` / `getSignupUrl`
        /// on this `Casdoor` instance, so there is no PKCE code verifier.
        case missingCodeVerifier
    }

    public let kind: Kind

    public init(kind: Kind) {
        self.kind = kind
    }

    /// URL provided to client is invalid
    public static var invalidURL: CasdoorError { .init(kind: .invalidURL) }

    public var description: String {
        switch kind {
        case .invalidURL:
            return "invalid URL, check endpoint and apiEndpoint in CasdoorConfig"
        case .responseMessage(let msg):
            return "response error: \(msg)"
        case .oauth(let error, let description):
            return "oauth error: \(error)" + (description.map { ", \($0)" } ?? "")
        case .invalidResponse(let statusCode, let body):
            return "unexpected response (HTTP \(statusCode)): \(body)"
        case .invalidJwt(let msg):
            return "invalid JWT: \(msg)"
        case .invalidCallback(let msg):
            return "invalid callback: \(msg)"
        case .missingCodeVerifier:
            return "no PKCE code verifier, call getSigninUrl() on the same Casdoor instance before exchanging the code"
        }
    }

    public var errorDescription: String? { description }
}
