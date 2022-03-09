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

#if compiler(>=5.5.2) && canImport(_Concurrency)

extension Casdoor {
    public func requestOauthAccessToken(code:String) async throws-> AccessTokenResponse {
        return try await self.requestOauthAccessToken(code: code).get()
    }
    
    public func renewToken(refreshToken: String,scope: String? = nil) async throws-> AccessTokenResponse {
        return try await self.renewToken(refreshToken: refreshToken, scope: scope).get()
    }
    public func logout(idToken: String,state: String? = nil) async throws -> Bool {
        return try await self.logout(idToken: idToken, state: state).get()
    }
}
#endif
