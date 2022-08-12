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
import CryptoKit

struct Utils {
   static func generate(count: Int) -> String {
       "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~".random(count: count)
    }
   static func generateNonce() -> String {
        generate(count: 10)
    }
   static func generateCodeVerifier() -> String {
        generate(count: 84)
    }
   static func generateCodeChallenge(_ verifier: String)-> String {
       return base64Url(base64:Data(SHA256.hash(data: verifier.data(using: .ascii)!)).base64EncodedString())
   }
   static func base64Url(base64: String) -> String {
        var base64 = base64
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
       if base64.hasSuffix("=") {
          _ = base64.popLast()
       }
        return base64
   }
}
extension String {
    func random(count: Int) -> String {
        var array:[Character] = .init(repeating: "0", count: count)
        (0..<count).forEach {
            array[$0] = self.randomElement()!
        }
        return String.init(array)
    }
}
