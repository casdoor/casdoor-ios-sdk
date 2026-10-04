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
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class Casdoor {
    /// Scope requested when `getSigninUrl` / `getSignupUrl` is called without one.
    /// "profile" makes `/api/userinfo` return the user's groups, roles and permissions.
    public static let defaultScope = "openid profile email"

    public let config: CasdoorConfig

    private let http: HTTPClient
    private let lock = NSLock()
    private var pendingAuthorization: PendingAuthorization?

    /// - Parameter session: the URLSession used for API calls, `.shared` by default.
    public init(config: CasdoorConfig, session: URLSession = .shared) {
        self.config = config
        self.http = HTTPClient(session: session)
    }
}

extension Casdoor: @unchecked Sendable {}

/// What `getSigninUrl` sent to Casdoor, needed again when the authorization code comes back.
struct PendingAuthorization {
    let codeVerifier: String
    let nonce: String
    let state: String
}

// MARK: - Sign in / sign up

extension Casdoor {
    /// The URL of Casdoor's sign-in page (authorization code flow with PKCE).
    /// Open it in `ASWebAuthenticationSession`, then pass the callback URL to `handleCallback(url:)`.
    public func getSigninUrl(scope: String? = nil, state: String? = nil) throws -> URL {
        try getAuthorizeUrl(path: "login/oauth/authorize", scope: scope, state: state)
    }

    /// Same as `getSigninUrl`, but opens Casdoor's sign-up page.
    public func getSignupUrl(scope: String? = nil, state: String? = nil) throws -> URL {
        try getAuthorizeUrl(path: "signup/oauth/authorize", scope: scope, state: state)
    }

    /// Checks the redirect URL Casdoor sent back (`<redirectUri>?code=...&state=...`)
    /// and exchanges the code for tokens.
    public func handleCallback(url: URL) async throws -> AccessTokenResponse {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw CasdoorError(kind: .invalidCallback("cannot parse callback url: \(url)"))
        }
        var params = [String: String]()
        for item in components.queryItems ?? [] {
            params[item.name] = item.value ?? ""
        }

        if let error = params["error"], !error.isEmpty {
            throw CasdoorError(kind: .oauth(error: error, description: params["error_description"]))
        }
        guard let code = params["code"], !code.isEmpty else {
            throw CasdoorError(kind: .invalidCallback("no code in callback url: \(url)"))
        }
        if let pending = currentPendingAuthorization(), params["state"] != pending.state {
            throw CasdoorError(kind: .invalidCallback("state mismatch, expected \(pending.state), got \(params["state"] ?? "nil")"))
        }
        return try await requestOauthAccessToken(code: code)
    }

    /// Exchanges the authorization code for tokens. Must be called on the same `Casdoor`
    /// instance that produced the sign-in URL, because it holds the PKCE code verifier.
    public func requestOauthAccessToken(code: String) async throws -> AccessTokenResponse {
        guard let pending = currentPendingAuthorization() else {
            throw CasdoorError(kind: .missingCodeVerifier)
        }
        let token = try await requestToken(path: "login/oauth/access_token", params: [
            ("grant_type", "authorization_code"),
            ("client_id", config.clientID),
            ("code", code),
            ("code_verifier", pending.codeVerifier),
            ("redirect_uri", config.redirectUri),
        ])

        if let idToken = token.idToken, !idToken.isEmpty {
            let claims = try Casdoor.decodeJwtPayload(idToken)
            if let nonce = claims["nonce"] as? String, !nonce.isEmpty, nonce != pending.nonce {
                throw CasdoorError(kind: .invalidJwt("nonce in id_token does not match the sign-in request"))
            }
        }

        clearPendingAuthorization()
        return token
    }

    /// Gets a new access token with the refresh token. When `scope` is nil the
    /// scope of the original grant is kept.
    public func renewToken(refreshToken: String, scope: String? = nil) async throws -> AccessTokenResponse {
        var params = [
            ("grant_type", "refresh_token"),
            ("client_id", config.clientID),
            ("refresh_token", refreshToken),
        ]
        if let scope = scope {
            params.append(("scope", scope))
        }
        return try await requestToken(path: "login/oauth/refresh_token", params: params)
    }
}

// MARK: - User info

extension Casdoor {
    /// Calls `/api/userinfo` (OIDC UserInfo endpoint) with the access token.
    public func getUserInfo(accessToken: String) async throws -> CasdoorUserInfo {
        let (data, response) = try await http.get(config.apiEndpoint + "userinfo", bearerToken: accessToken)
        _ = try ResponseParser.jsonObject(data, response)
        return try ResponseParser.decode(CasdoorUserInfo.self, data, response)
    }

    /// Decodes the payload of a JWT (for example `idToken`) into a dictionary.
    /// The signature is NOT verified, so only use it to read claims of a token you
    /// received directly from Casdoor over HTTPS.
    public static func decodeJwtPayload(_ jwt: String) throws -> [String: Any] {
        let segments = jwt.split(separator: ".", omittingEmptySubsequences: false)
        guard segments.count == 3 else {
            throw CasdoorError(kind: .invalidJwt("expected 3 segments, got \(segments.count)"))
        }
        guard let data = Base64Url.decode(String(segments[1])),
              let object = try? JSONSerialization.jsonObject(with: data),
              let claims = object as? [String: Any] else {
            throw CasdoorError(kind: .invalidJwt("payload is not base64url encoded JSON"))
        }
        return claims
    }
}

// MARK: - Sign out

extension Casdoor {
    /// Ends the login on the server: expires the token behind `idToken` and its refresh token.
    ///
    /// The Casdoor session cookie kept by the browser used to sign in (for example
    /// `ASWebAuthenticationSession`) is not touched, so the next sign-in may complete without
    /// asking for the password. To end that too, open `getSignoutUrl(idToken:)` in the browser
    /// instead of calling this method.
    @discardableResult
    public func logout(idToken: String, state: String? = nil) async throws -> Bool {
        var params = [("id_token_hint", idToken)]
        if let state = state {
            params.append(("state", state))
        }
        let (data, response) = try await http.postForm(config.apiEndpoint + "logout", params)
        let json = try ResponseParser.jsonObject(data, response)
        return (json["status"] as? String) == "ok"
    }

    /// The URL of Casdoor's RP-initiated logout endpoint. Opening it in the same browser used for
    /// sign-in expires the token, clears the Casdoor session cookie, and then redirects to
    /// `postLogoutRedirectUri` (default `config.redirectUri`, which must be in the application's
    /// Redirect URLs list).
    public func getSignoutUrl(idToken: String, postLogoutRedirectUri: String? = nil, state: String? = nil) throws -> URL {
        var params = [
            ("id_token_hint", idToken),
            ("post_logout_redirect_uri", postLogoutRedirectUri ?? config.redirectUri),
        ]
        if let state = state {
            params.append(("state", state))
        }
        return try makeUrl(config.apiEndpoint + "logout", params)
    }
}

// MARK: - Internals

extension Casdoor {
    private func getAuthorizeUrl(path: String, scope: String?, state: String?) throws -> URL {
        let pending = PendingAuthorization(
            codeVerifier: PKCE.generateCodeVerifier(),
            nonce: PKCE.randomString(count: 32),
            state: state ?? config.appName
        )
        let url = try makeUrl(config.endpoint + path, [
            ("client_id", config.clientID),
            ("response_type", "code"),
            ("redirect_uri", config.redirectUri),
            ("scope", scope ?? Casdoor.defaultScope),
            ("state", pending.state),
            ("nonce", pending.nonce),
            ("code_challenge_method", "S256"),
            ("code_challenge", PKCE.codeChallenge(for: pending.codeVerifier)),
        ])
        lock.lock()
        pendingAuthorization = pending
        lock.unlock()
        return url
    }

    private func makeUrl(_ base: String, _ params: [(String, String)]) throws -> URL {
        guard var components = URLComponents(string: base) else {
            throw CasdoorError.invalidURL
        }
        components.percentEncodedQuery = FormEncoding.encode(params)
        guard let url = components.url else {
            throw CasdoorError.invalidURL
        }
        return url
    }

    private func requestToken(path: String, params: [(String, String)]) async throws -> AccessTokenResponse {
        let (data, response) = try await http.postForm(config.apiEndpoint + path, params)
        _ = try ResponseParser.jsonObject(data, response)
        let token = try ResponseParser.decode(AccessTokenResponse.self, data, response)
        // Casdoor before 2023 reported errors as {"access_token": "<message>", "expires_in": 0, ...}
        if token.expiresIn == 0 && (token.refreshToken ?? "").isEmpty {
            throw CasdoorError(kind: .responseMessage(token.accessToken))
        }
        return token
    }

    private func currentPendingAuthorization() -> PendingAuthorization? {
        lock.lock()
        defer { lock.unlock() }
        return pendingAuthorization
    }

    private func clearPendingAuthorization() {
        lock.lock()
        pendingAuthorization = nil
        lock.unlock()
    }
}
