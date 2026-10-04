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

struct HTTPClient {
    let session: URLSession

    func postForm(_ urlString: String, _ params: [(String, String)]) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: urlString) else {
            throw CasdoorError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = Data(FormEncoding.encode(params).utf8)
        return try await send(request)
    }

    func get(_ urlString: String, bearerToken: String) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: urlString) else {
            throw CasdoorError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        return try await send(request)
    }

    // URLSession.data(for:) needs iOS 15, so wrap the completion handler API.
    private func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let response = response as? HTTPURLResponse else {
                    continuation.resume(throwing: CasdoorError(kind: .invalidResponse(statusCode: 0, body: "not an HTTP response")))
                    return
                }
                continuation.resume(returning: (data ?? Data(), response))
            }
            task.resume()
        }
    }
}

enum ResponseParser {
    /// Parses the body as a JSON object and turns Casdoor / OAuth error bodies into `CasdoorError`.
    static func jsonObject(_ data: Data, _ response: HTTPURLResponse) throws -> [String: Any] {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let json = object as? [String: Any] else {
            throw invalidResponse(data, response)
        }
        if let error = json["error"] as? String, !error.isEmpty {
            throw CasdoorError(kind: .oauth(error: error, description: json["error_description"] as? String))
        }
        if let status = json["status"] as? String, status == "error" {
            throw CasdoorError(kind: .responseMessage(json["msg"] as? String ?? ""))
        }
        if !(200..<300).contains(response.statusCode) {
            throw invalidResponse(data, response)
        }
        return json
    }

    static func decode<T: Decodable>(_ type: T.Type, _ data: Data, _ response: HTTPURLResponse) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw invalidResponse(data, response)
        }
    }

    private static func invalidResponse(_ data: Data, _ response: HTTPURLResponse) -> CasdoorError {
        let body = String(decoding: data.prefix(500), as: UTF8.self)
        return CasdoorError(kind: .invalidResponse(statusCode: response.statusCode, body: body))
    }
}

enum FormEncoding {
    // RFC 3986 unreserved characters, everything else is percent-encoded
    private static let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")

    static func encode(_ params: [(String, String)]) -> String {
        params.map { "\(escape($0.0))=\(escape($0.1))" }.joined(separator: "&")
    }

    static func escape(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }
}
