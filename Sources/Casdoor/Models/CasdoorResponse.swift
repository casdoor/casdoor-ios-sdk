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

struct CasdoorResponse<D1,D2>: Decodable where D1:Decodable,D2:Decodable {
    let status: String
    let msg: String
    let data: D1?
    let data2: D2?
    
    func isOk() throws {
        guard status == "error" else {
            throw CasdoorError.init(error: .responseMessage(msg))
        }
    }
}

typealias CasdoorOneDataResponse<D:Decodable> = CasdoorResponse<D,String>
typealias CasdoorNoDataResponse = CasdoorResponse<String,String>
