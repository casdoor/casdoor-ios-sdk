import Foundation
import AF

public final class Casdoor {
    public init(config: CasdoorConfig) {
        self.config = config
    }
    public let config: CasdoorConfig
    
    var codeVerifier: String!
    var nonce: String!
}

//Apis

extension Casdoor {
    public func getSigninUrl(scope:String? = nil,state:String? = nil) throws -> URL {
        self.codeVerifier = Utils.generateCodeVerifier()
        let url = "\(config.endpoint)login/oauth/authorize"
        self.nonce = Utils.generateNonce()
        let query = CodeRequestQuery.init(config: config, nonce: nonce!, scope: scope, state: state, codeVerifier: codeVerifier!)
        let urlRequst: URLRequest = try .init(url: url, method: .get)
        guard let uri = try query.toUrl(request: urlRequst).url else {
            throw CasdoorError.invalidURL
        }
        return uri
    }
    public func getSignupUrl(
        scope:String? = nil,
        state:String? = nil
    ) throws -> URL {
        let urlString = try getSigninUrl(scope: scope, state: state)
            .absoluteString
            .replacingOccurrences(
                of: "/login/oauth/authorize",
                with: "/signup/oauth/authorize")
        guard let uri = URL.init(string: urlString) else {
            throw CasdoorError.invalidURL
        }
        return uri
    }
    
    public func requestOauthAccessToken(code:String) async throws-> AccessTokenResponse {
        let query = AccessTokenRequest.init(clientID: config.clientID, code: code, verifier: codeVerifier)
        let url = "\(config.apiEndpoint)login/oauth/access_token"
        let token = try await AF.request(url, method: .post, parameters: query, encoder: URLEncodedFormParameterEncoder.default).serializingDecodable(AccessTokenResponse.self).value
        if token.refreshToken == nil {
            throw CasdoorError.init(error: .responseMessage(token.accessToken))
        }
        return token
    }
    
    public func renewToken(refreshToken: String,scope: String? = nil) async throws -> AccessTokenResponse {
        let query = ReNewAccessTokenRequest.init(clientID: config.clientID, scope: scope ?? "read", refreshToken: refreshToken)
        let url = "\(config.apiEndpoint)login/oauth/refresh_token"
        let token = try await AF.request(url, method: .post, parameters: query, encoder: URLEncodedFormParameterEncoder.default).serializingDecodable(AccessTokenResponse.self).value
        if token.refreshToken == nil || token.refreshToken!.isEmpty {
            throw CasdoorError.init(error: .responseMessage(token.accessToken))
        }
        return token
    }
    
    public func logout(idToken: String,state: String? = nil) async throws -> Bool {
        let query = ["id_token_hint":idToken,"state":state ?? config.appName]
        let url = "\(config.apiEndpoint)login/oauth/logout"
        
        let resData = try await AF.request(url, method: .post, parameters: query, encoder: URLEncodedFormParameterEncoder.default).serializingDecodable(CasdoorNoDataResponse.self).value
        try resData.isOk()
        if let isAffected = resData.data,!isAffected.isEmpty {
            return isAffected == "Affected"
        }
        return false
    }
}

