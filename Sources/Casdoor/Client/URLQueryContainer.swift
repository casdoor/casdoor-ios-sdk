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

struct URLQueryContainer {
    var url: URI

    func decode<D>(_ decodable: D.Type) throws -> D
        where D: Decodable
    {
        return try ContentConfiguration.global.urlDecoder.decode(D.self, from: self.url)
    }

    mutating func encode<E>(_ encodable: E) throws
        where E: Encodable
    {
        try ContentConfiguration.global.urlEncoder.encode(encodable, to: &self.url)
    }
}
