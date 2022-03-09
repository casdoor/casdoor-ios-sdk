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
import NIOHTTP1

struct ClientRequest {
    public var method: HTTPMethod
    public var url: URI
    public var headers: HTTPHeaders
    public var body: ByteBuffer?

    public init(
        method: HTTPMethod = .GET,
        url: URI = "/",
        headers: HTTPHeaders = [:],
        body: ByteBuffer? = nil
    ) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
    }
}

extension ClientRequest {
    public var query: URLQueryContainer {
        get {
            return URLQueryContainer(url: self.url)
        }
        set {
            self.url = newValue.url
        }
    }
    public var content: ContentContainer {
        get {
            return ContentContainer(body: self.body, headers: self.headers)
        }
        set {
            let container = newValue
            self.body = container.body
            self.headers = container.headers
        }
    }
}
