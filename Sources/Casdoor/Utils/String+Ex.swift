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

extension String {
    /// Parses "a=1&b=2&c" into ["a": "1", "b": "2", "c": ""], percent-decoding keys and values.
    public var parametersFromQueryString: [String: String] {
        var parameters = [String: String]()
        for pair in split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            let key = decode(parts[0])
            if key.isEmpty {
                continue
            }
            parameters[key] = parts.count > 1 ? decode(parts[1]) : ""
        }
        return parameters
    }

    private func decode(_ component: Substring) -> String {
        let string = component.replacingOccurrences(of: "+", with: " ")
        return string.removingPercentEncoding ?? string
    }
}
