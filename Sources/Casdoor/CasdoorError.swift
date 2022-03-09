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

public struct CasdoorError: Swift.Error,CustomStringConvertible {
    public var description: String {
        switch error {
        case .alreadyShutdown:
            return "The CasdoorClient is already shutdown"
        case .invalidURL:
            return """
            The request url is invalid format.
            This error is internal. So please make a issue on https://github.com/casdoor/casdoor-ios-sdk/issues to solve it.
            """
        case .responseMessage(let s):
            return "response error: \(s)"
        case .invalidJwt(let s):
            return "invalidJWT: \(s)"
        }
    }
    
    enum Error {
        case alreadyShutdown
        case invalidURL
        case responseMessage(String)
        case invalidJwt(String)
    }

    let error: Error

    /// client has already been shutdown
    public static var alreadyShutdown: CasdoorError { .init(error: .alreadyShutdown) }
    /// URL provided to client is invalid
    public static var invalidURL: CasdoorError { .init(error: .invalidURL) }
}
