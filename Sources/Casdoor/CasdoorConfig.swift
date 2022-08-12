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

public struct CasdoorConfig {
    public init(
        endpoint: String,
        clientID: String,
        organizationName: String,
        redirectUri: String,
        appName: String,
        apiEndpoint: String? = nil
        ) {
        self.clientID = clientID
        self.organizationName = organizationName
        self.redirectUri = redirectUri
        self.appName = appName
        self.endpoint = formatEndpoint(url: endpoint)
        if let apiEndpoint = apiEndpoint {
            self.apiEndpoint = formatEndpoint(url:apiEndpoint)
        } else {
            self.apiEndpoint = self.endpoint + "api/"
        }
    }
    
    public let clientID: String
    public let organizationName: String
    public let redirectUri: String
    public let apiEndpoint: String
    public let endpoint: String
    public let appName: String
}

fileprivate func formatEndpoint(url:String) -> String {
    let url = url.trimmingCharacters(in: .whitespaces)
    return url.hasSuffix("/") ? url : url + "/"
}
