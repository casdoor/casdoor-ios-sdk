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

import AsyncHTTPClient
import Logging
import NIOCore
import NIOHTTP1
import Foundation

struct EventLoopHTTPClient {
    let http: HTTPClient
    let eventLoop: EventLoop
    var logger: Logger?
    let loggerLevel: Logger.Level
    
    func send(
        _ client: ClientRequest
    ) -> EventLoopFuture<ClientResponse> {
        let urlString = client.url.string
        guard let url = URL(string: urlString) else {
            self.logger?.debug("\(urlString) is an invalid URL")
            return self.eventLoop.makeFailedFuture(CasdoorError.invalidURL)
        }
        do {
            logRequest(request: client)
            let request = try HTTPClient.Request(
                url: url,
                method: client.method,
                headers: client.headers,
                body: client.body.map { .byteBuffer($0) }
            )
            return self.http.execute(
                request: request,
                eventLoop: .delegate(on: self.eventLoop),
                logger: logger
            ).map { response in
                let client = ClientResponse(
                    status: response.status,
                    headers: response.headers,
                    body: response.body
                )
                logResponse(response: client)
                return client
            }
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }
}

extension HTTPClient {
    func delegating(to eventLoop: EventLoop, logger: Logger,loggerLevel: Logger.Level) -> EventLoopHTTPClient {
        EventLoopHTTPClient(
            http: self,
            eventLoop: eventLoop,
            logger: logger,
            loggerLevel: loggerLevel
        )
    }
}

extension EventLoopHTTPClient {
    func get(_ url: URI, headers: HTTPHeaders = [:], beforeSend: (inout ClientRequest) throws -> () = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(.GET, headers: headers, to: url, beforeSend: beforeSend)
    }

    func post(_ url: URI, headers: HTTPHeaders = [:], beforeSend: (inout ClientRequest) throws -> () = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(.POST, headers: headers, to: url, beforeSend: beforeSend)
    }

    func patch(_ url: URI, headers: HTTPHeaders = [:], beforeSend: (inout ClientRequest) throws -> () = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(.PATCH, headers: headers, to: url, beforeSend: beforeSend)
    }

    func put(_ url: URI, headers: HTTPHeaders = [:], beforeSend: (inout ClientRequest) throws -> () = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(.PUT, headers: headers, to: url, beforeSend: beforeSend)
    }

    func delete(_ url: URI, headers: HTTPHeaders = [:], beforeSend: (inout ClientRequest) throws -> () = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(.DELETE, headers: headers, to: url, beforeSend: beforeSend)
    }

    func send(
        _ method: HTTPMethod,
        headers: HTTPHeaders = [:],
        to url: URI,
        beforeSend: (inout ClientRequest) throws -> () = { _ in }
    ) -> EventLoopFuture<ClientResponse> {
        var request = ClientRequest(method: method, url: url, headers: headers, body: nil)
        do {
            try beforeSend(&request)
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
        return self.send(request)
    }
}

fileprivate extension EventLoopHTTPClient {
    func getBodyOutput(_ body: ByteBuffer?) -> String {
        var output = ""
        if let body = body {
            output += "\n  "
            output += body.getString(at: body.readerIndex, length: body.readableBytes) ?? "Failed to convert JSON response to UTF8"
        } else {
            output += "empty"
        }
        return output
    }
    func getHeadersOutput(_ headers: HTTPHeaders) -> String {
        if headers.count == 0 {
            return "[]"
        }
        var output = "["
        for header in headers {
            output += "\n    \(header.name) : \(header.value)"
        }
        return output + "\n  ]"
    }
    func logRequest(request:ClientRequest) {
        let message = "Request:\n" +
        "  \(request.method) \(request.url.string)\n" +
        "  Headers: \(self.getHeadersOutput(request.headers))\n" +
        "  Body: \(self.getBodyOutput(request.body))"
        logger?.log(level:loggerLevel,.init(stringLiteral: message) )
    }
    func logResponse(response:ClientResponse) {
        let message = "Response:\n" +
        "  Status : \(response.status.code)\n" +
        "  Headers: \(self.getHeadersOutput(HTTPHeaders(response.headers.map { ($0, "\($1)") })))\n" +
        "  Body: \(self.getBodyOutput(response.body))"
        logger?.log(level:loggerLevel,.init(stringLiteral: message) )
    }
}
