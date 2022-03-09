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

import NIOCore
import JWTKit


public final class Casdoor {
    let config: CasdoorConfig
    let client: CasdoorClient
    var codeVerifier: String!
    var nonce: String!
    
    public init(
        client: CasdoorClient,
        config: CasdoorConfig
    ) {
        self.config = config
        self.client = client
    }
    
    public func getSigninUrl(scope:String? = nil,state:String? = nil) throws -> String {
        self.codeVerifier = Utils.generateCodeVerifier()
        let url:URI = "\(config.endpoint)login/oauth/authorize"
        self.nonce = Utils.generateNonce()
        let query = CodeRequestQuery.init(config: config, nonce: nonce!, scope: scope, state: state, codeVerifier: codeVerifier!)
        var container = URLQueryContainer.init(url: url)
        try container.encode(query)
        return container.url.string
    }
    public func getSignupUrl(
        scope:String? = nil,
        state:String? = nil
    ) throws -> String {
        return try getSigninUrl(scope: scope, state: state)
                .replacingOccurrences(
                    of: "/login/oauth/authorize",
                    with: "/signup/oauth/authorize")
    }
    
    public func requestOauthAccessToken(code:String) -> EventLoopFuture<AccessTokenResponse> {
        let query = AccessTokenRequest.init(clientID: config.clientID, code: code, verifier: codeVerifier)
        let url:URI = "\(config.apiEndpoint)login/oauth/access_token"
        return  client.httpClient.post(url) { req in
           try req.query.encode(query)
        }.flatMapThrowing { res in
           let token = try res.content.decode(AccessTokenResponse.self)
            if token.refreshToken == nil {
                throw CasdoorError.init(error: .responseMessage(token.accessToken))
            }
            return token
        }
    }
    public func verifyToken(token: String) throws -> Payload {
        do {
            let signers = JWTSigners.init()
            signers.use(.rs256(key: try .certificate(pem: config.jwtSecret)))
            let payload = try signers.verify(token, as: Payload.self)
            guard payload.nonce != self.nonce else {
                throw CasdoorError.init(error: .invalidJwt("nonce don't match."))
            }
            return payload
        } catch let jwtError as JWTError {
            throw CasdoorError.init(error: .invalidJwt(jwtError.reason))
        } catch {
            throw error
        }
    }
    public func renewToken(refreshToken: String,scope: String? = nil) -> EventLoopFuture<AccessTokenResponse> {
        let query = ReNewAccessTokenRequest.init(clientID: config.clientID, scope: scope ?? "read", refreshToken: refreshToken)
        let url:URI = "\(config.apiEndpoint)login/oauth/refresh_token"
        return client.httpClient.post(url) { req in
            try req.query.encode(query)
        }.flatMapThrowing { res in
            let token = try res.content.decode(AccessTokenResponse.self)
            if token.refreshToken == nil || token.refreshToken!.isEmpty {
                 throw CasdoorError.init(error: .responseMessage(token.accessToken))
             }
            return token
        }
    }
    public func logout(idToken: String,state: String? = nil) -> EventLoopFuture<Bool> {
        let query = ["id_token_hint":idToken,"state":state ?? config.appName]
        let url:URI = "\(config.apiEndpoint)login/oauth/logout"
        return client.httpClient.post(url) { req in
           try req.query.encode(query)
        }.flatMapThrowing { res in
            let resData = try res.content.decode(CasdoorNoDataResponse.self)
            try resData.isOk()
            if let isAffected = resData.data,!isAffected.isEmpty {
                return isAffected == "Affected"
            }
            return false
        }
    }
}
