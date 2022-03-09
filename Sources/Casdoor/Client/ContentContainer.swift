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

struct ContentContainer {
    var body: ByteBuffer?
    var headers: HTTPHeaders

    mutating func encodeAsQuery<E>(_ encodable: E) throws where E : Encodable {
        var body = ByteBufferAllocator().buffer(capacity: 0)
        try ContentConfiguration.global.urlEncoder.encode(encodable, to: &body, headers: &self.headers)
        self.body = body
    }
    mutating func encodeAsJSON<E>(_ encodable: E) throws where E : Encodable {
        var body = ByteBufferAllocator().buffer(capacity: 0)
        try ContentConfiguration.global.jsonEncoder.encode(encodable, to: &body,headers: &headers)
        self.body = body
    }
    
    func decode<D>(_ decodable: D.Type) throws -> D where D : Decodable {
        guard let body = self.body else {
           throw CasdoorError.init(error: .responseMessage(HTTPResponseStatus.lengthRequired.reasonPhrase))
        }
        return try ContentConfiguration.global.josnDecoder.decode(D.self, from: body)
    }
}


