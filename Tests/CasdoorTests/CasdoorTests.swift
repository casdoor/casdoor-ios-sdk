import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import Casdoor

final class CasdoorTests: XCTestCase {
    private let config = CasdoorConfig(
        endpoint: "https://door.example.com",
        clientID: "client-id",
        organizationName: "built-in",
        redirectUri: "casdoor://callback",
        appName: "app-example"
    )

    private var casdoor: Casdoor!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        casdoor = Casdoor(config: config, session: URLSession(configuration: configuration))
        MockURLProtocol.handler = nil
    }

    // MARK: - URLs

    func testSigninUrl() throws {
        let url = try casdoor.getSigninUrl()
        XCTAssertEqual(url.host, "door.example.com")
        XCTAssertEqual(url.path, "/login/oauth/authorize")

        let query = try XCTUnwrap(url.query).parametersFromQueryString
        XCTAssertEqual(query["client_id"], "client-id")
        XCTAssertEqual(query["response_type"], "code")
        XCTAssertEqual(query["redirect_uri"], "casdoor://callback")
        XCTAssertEqual(query["scope"], "openid profile email")
        XCTAssertEqual(query["state"], "app-example")
        XCTAssertEqual(query["code_challenge_method"], "S256")
        XCTAssertEqual(query["code_challenge"]?.count, 43)
        XCTAssertEqual(query["nonce"]?.count, 32)
        XCTAssertTrue(url.absoluteString.contains("redirect_uri=casdoor%3A%2F%2Fcallback"))
    }

    func testSignupUrl() throws {
        let url = try casdoor.getSignupUrl(scope: "read", state: "s1")
        XCTAssertEqual(url.path, "/signup/oauth/authorize")
        let query = try XCTUnwrap(url.query).parametersFromQueryString
        XCTAssertEqual(query["scope"], "read")
        XCTAssertEqual(query["state"], "s1")
    }

    func testSignoutUrl() throws {
        let url = try casdoor.getSignoutUrl(idToken: "id.token.value", state: "bye")
        XCTAssertEqual(url.path, "/api/logout")
        let query = try XCTUnwrap(url.query).parametersFromQueryString
        XCTAssertEqual(query["id_token_hint"], "id.token.value")
        XCTAssertEqual(query["post_logout_redirect_uri"], "casdoor://callback")
        XCTAssertEqual(query["state"], "bye")
    }

    func testApiEndpoint() {
        XCTAssertEqual(config.apiEndpoint, "https://door.example.com/api/")
        let custom = CasdoorConfig(endpoint: "https://a.com/", clientID: "c", organizationName: "o",
                                   redirectUri: "r", appName: "a", apiEndpoint: " https://b.com/api ")
        XCTAssertEqual(custom.endpoint, "https://a.com/")
        XCTAssertEqual(custom.apiEndpoint, "https://b.com/api/")
    }

    // MARK: - Helpers

    func testPkceChallengeMatchesRfc7636() {
        // RFC 7636 Appendix B
        XCTAssertEqual(PKCE.codeChallenge(for: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"),
                       "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }

    func testSha256() {
        let hex = { (data: Data) in data.map { String(format: "%02x", $0) }.joined() }
        XCTAssertEqual(hex(PKCE.sha256(Data())), "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        XCTAssertEqual(hex(PKCE.sha256(Data(String(repeating: "a", count: 1000).utf8))),
                       "41edece42d63e8d9bf515a9ba6932e1c20cbc9f5a5d134645adb5db1b9737ea3")
    }

    func testCodeVerifier() {
        let verifier = PKCE.generateCodeVerifier()
        XCTAssertEqual(verifier.count, 64)
        XCTAssertNotEqual(verifier, PKCE.generateCodeVerifier())
    }

    func testFormEncoding() {
        XCTAssertEqual(FormEncoding.encode([("a b", "1+2&3=4/é")]), "a%20b=1%2B2%263%3D4%2F%C3%A9")
    }

    func testParametersFromQueryString() {
        let params = "code=a%2Bb&state=x+y&flag&=skip".parametersFromQueryString
        XCTAssertEqual(params, ["code": "a+b", "state": "x y", "flag": ""])
    }

    func testDecodeJwtPayload() throws {
        let claims = try Casdoor.decodeJwtPayload(makeJwt(["name": "alice", "owner": "built-in"]))
        XCTAssertEqual(claims["name"] as? String, "alice")
        XCTAssertThrowsError(try Casdoor.decodeJwtPayload("not-a-jwt"))
    }

    // MARK: - Token

    func testHandleCallbackExchangesCode() async throws {
        let signinQuery = try XCTUnwrap(casdoor.getSigninUrl().query).parametersFromQueryString
        let nonce = try XCTUnwrap(signinQuery["nonce"])
        let challenge = try XCTUnwrap(signinQuery["code_challenge"])

        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.absoluteString, "https://door.example.com/api/login/oauth/access_token")
            let body = request.bodyString.parametersFromQueryString
            XCTAssertEqual(body["grant_type"], "authorization_code")
            XCTAssertEqual(body["client_id"], "client-id")
            XCTAssertEqual(body["code"], "the-code")
            XCTAssertEqual(PKCE.codeChallenge(for: body["code_verifier"] ?? ""), challenge)
            return (200, self.tokenJson(idToken: makeJwt(["nonce": nonce])))
        }

        let token = try await casdoor.handleCallback(url: URL(string: "casdoor://callback?code=the-code&state=app-example")!)
        XCTAssertEqual(token.accessToken, "access")
        XCTAssertEqual(token.refreshToken, "refresh")
        XCTAssertEqual(token.expiresIn, 3600)

        // The verifier is single use
        do {
            _ = try await casdoor.requestOauthAccessToken(code: "the-code")
            XCTFail("expected missingCodeVerifier")
        } catch let error as CasdoorError {
            XCTAssertEqual(error.kind, .missingCodeVerifier)
        }
    }

    func testHandleCallbackRejectsWrongState() async throws {
        _ = try casdoor.getSigninUrl(state: "expected")
        await assertThrows(.invalidCallback("state mismatch, expected expected, got other")) {
            _ = try await self.casdoor.handleCallback(url: URL(string: "casdoor://callback?code=c&state=other")!)
        }
    }

    func testHandleCallbackWithError() async throws {
        _ = try casdoor.getSigninUrl()
        await assertThrows(.oauth(error: "access_denied", description: "user cancelled")) {
            _ = try await self.casdoor.handleCallback(url: URL(string: "casdoor://callback?error=access_denied&error_description=user%20cancelled")!)
        }
    }

    func testNonceMismatch() async throws {
        _ = try casdoor.getSigninUrl()
        MockURLProtocol.handler = { _ in (200, self.tokenJson(idToken: makeJwt(["nonce": "someone-else"]))) }
        await assertThrows(.invalidJwt("nonce in id_token does not match the sign-in request")) {
            _ = try await self.casdoor.requestOauthAccessToken(code: "c")
        }
    }

    func testTokenWithoutSignin() async {
        await assertThrows(.missingCodeVerifier) {
            _ = try await self.casdoor.requestOauthAccessToken(code: "c")
        }
    }

    func testTokenOauthError() async throws {
        _ = try casdoor.getSigninUrl()
        MockURLProtocol.handler = { _ in
            (400, Data(#"{"error":"invalid_grant","error_description":"authorization code has been used"}"#.utf8))
        }
        await assertThrows(.oauth(error: "invalid_grant", description: "authorization code has been used")) {
            _ = try await self.casdoor.requestOauthAccessToken(code: "c")
        }
    }

    func testTokenLegacyError() async throws {
        _ = try casdoor.getSigninUrl()
        MockURLProtocol.handler = { _ in
            (200, Data(#"{"access_token":"Error: invalid code","token_type":"","refresh_token":"","expires_in":0,"scope":""}"#.utf8))
        }
        await assertThrows(.responseMessage("Error: invalid code")) {
            _ = try await self.casdoor.requestOauthAccessToken(code: "c")
        }
    }

    func testRenewTokenKeepsOriginalScope() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/login/oauth/refresh_token")
            let body = request.bodyString.parametersFromQueryString
            XCTAssertEqual(body["grant_type"], "refresh_token")
            XCTAssertEqual(body["refresh_token"], "old-refresh")
            XCTAssertNil(body["scope"])
            return (200, self.tokenJson(idToken: nil))
        }
        let token = try await casdoor.renewToken(refreshToken: "old-refresh")
        XCTAssertEqual(token.accessToken, "access")
        XCTAssertNil(token.idToken)
    }

    // MARK: - Logout

    func testLogout() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.absoluteString, "https://door.example.com/api/logout")
            XCTAssertEqual(request.bodyString.parametersFromQueryString, ["id_token_hint": "the-id-token"])
            return (200, Data(#"{"status":"ok","msg":"","sub":"","name":"","data":null,"data2":null,"data3":null}"#.utf8))
        }
        let ok = try await casdoor.logout(idToken: "the-id-token")
        XCTAssertTrue(ok)
    }

    func testLogoutErrorMessage() async {
        MockURLProtocol.handler = { _ in
            (200, Data(#"{"status":"error","msg":"Token not found, invalid accessToken","data":null}"#.utf8))
        }
        await assertThrows(.responseMessage("Token not found, invalid accessToken")) {
            try await self.casdoor.logout(idToken: "bad")
        }
    }

    func testHtmlResponse() async {
        MockURLProtocol.handler = { _ in (404, Data("<!DOCTYPE html><html>404</html>".utf8)) }
        await assertThrows(.invalidResponse(statusCode: 404, body: "<!DOCTYPE html><html>404</html>")) {
            try await self.casdoor.logout(idToken: "x")
        }
    }

    // MARK: - User info

    func testGetUserInfo() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.absoluteString, "https://door.example.com/api/userinfo")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access")
            return (200, Data(#"""
            {"sub":"0d9e","iss":"https://door.example.com","aud":"client-id","preferred_username":"alice",
             "name":"Alice","email":"alice@example.com","email_verified":true,"picture":"https://a/p.png",
             "groups":["built-in/staff"],"roles":["built-in/admin"],"permissions":["built-in/read"]}
            """#.utf8))
        }
        let info = try await casdoor.getUserInfo(accessToken: "access")
        XCTAssertEqual(info.sub, "0d9e")
        XCTAssertEqual(info.name, "alice")
        XCTAssertEqual(info.displayName, "Alice")
        XCTAssertTrue(info.emailVerified)
        XCTAssertEqual(info.avatar, "https://a/p.png")
        XCTAssertEqual(info.roles, ["built-in/admin"])
        XCTAssertEqual(info.permissions, ["built-in/read"])
        XCTAssertEqual(info.phone, nil)
    }

    func testGetUserInfoUnauthorized() async {
        MockURLProtocol.handler = { _ in (401, Data(#"{"status":"error","msg":"Please sign in first"}"#.utf8)) }
        await assertThrows(.responseMessage("Please sign in first")) {
            _ = try await self.casdoor.getUserInfo(accessToken: "expired")
        }
    }

    // MARK: - Utilities

    private func tokenJson(idToken: String?) -> Data {
        var json: [String: Any] = [
            "access_token": "access",
            "refresh_token": "refresh",
            "token_type": "Bearer",
            "expires_in": 3600,
            "scope": "openid profile email",
        ]
        json["id_token"] = idToken
        return try! JSONSerialization.data(withJSONObject: json)
    }

    private func assertThrows(_ expected: CasdoorError.Kind, file: StaticString = #filePath, line: UInt = #line,
                              _ body: @escaping () async throws -> Void) async {
        do {
            try await body()
            XCTFail("expected \(expected)", file: file, line: line)
        } catch let error as CasdoorError {
            XCTAssertEqual(error.kind, expected, file: file, line: line)
        } catch {
            XCTFail("unexpected error \(error)", file: file, line: line)
        }
    }
}

private func makeJwt(_ claims: [String: Any]) -> String {
    let header = Base64Url.encode(Data(#"{"alg":"RS256","typ":"JWT"}"#.utf8))
    let payload = Base64Url.encode(try! JSONSerialization.data(withJSONObject: claims))
    return "\(header).\(payload).signature"
}

final class MockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (Int, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (status, data) = try handler(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

extension URLRequest {
    /// URLSession moves httpBody into httpBodyStream before URLProtocol sees it.
    var bodyString: String {
        if let body = httpBody {
            return String(decoding: body, as: UTF8.self)
        }
        guard let stream = httpBodyStream else {
            return ""
        }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 {
                break
            }
            data.append(buffer, count: count)
        }
        return String(decoding: data, as: UTF8.self)
    }
}
