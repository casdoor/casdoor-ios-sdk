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

struct CodeRequestQuery: Encodable {
    let clientID: String
    let responseType: String
    let scope: String
    let state: String
    let nonce: String
    let codeChallengeMethod: String
    let codeChallenge: String
    let redirectUri:String
    
    enum CodingKeys: String,CodingKey {
        case clientID = "client_id"
        case responseType = "response_type"
        case scope,state,nonce
        case codeChallengeMethod = "code_challenge_method"
        case codeChallenge = "code_challenge"
        case redirectUri = "redirect_uri"
    }
    init(config:CasdoorConfig,
         nonce:String,
         scope: String? = nil,
         state: String? = nil,
         codeVerifier: String
    ) {
        self.clientID = config.clientID
        self.responseType = "code"
        self.redirectUri = config.redirectUri
        self.scope = scope ?? "read"
        self.state = state ?? config.appName
        self.codeChallengeMethod = "S256"
        self.nonce = nonce
        self.codeChallenge = Utils.generateCodeChallenge(codeVerifier)
    }
}

struct AccessTokenRequest: Encodable {
    init(grantType: String = "authorization_code",
                clientID: String,
                code: String,
                verifier: String
      ) {
        self.grantType = grantType
        self.clientID = clientID
        self.code = code
        self.verifier = verifier
    }
    let grantType: String
    let clientID: String
    let code: String
    let verifier: String
    
    enum CodingKeys: String,CodingKey {
        case clientID = "client_id"
        case code
        case grantType = "grant_type"
        case verifier = "code_verifier"
    }
    
}
struct ReNewAccessTokenRequest: Encodable {
    internal init(grantType: String = "refresh_token",
                  clientID: String,
                  scope: String,
                  refreshToken: String) {
        self.grantType = grantType
        self.clientID = clientID
        self.scope = scope
        self.refreshToken = refreshToken
    }
    
    let grantType: String
    let clientID: String
    let scope: String
    let refreshToken: String
    enum CodingKeys: String,CodingKey {
        case clientID = "client_id"
        case scope
        case grantType = "grant_type"
        case refreshToken = "refresh_token"
    }
}

public struct AccessTokenResponse:Decodable {
   public let accessToken: String
   public let idToken: String?
   public let refreshToken: String?
   public let tokenType: String
   public let expiresIn: Int
   public let scope: String
    enum CodingKeys: String,CodingKey {
        case accessToken = "access_token"
        case idToken = "id_token"
        case tokenType = "token_type"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case scope
    }
}
