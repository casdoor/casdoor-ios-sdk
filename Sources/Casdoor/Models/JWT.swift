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

import JWTKit
import Foundation

// MARK: - Jwt
public struct Payload:JWTPayload {
    public func verify(using signer: JWTSigner) throws {
       try self.exp.verifyNotExpired()
       try self.nbf.verifyNotBefore()
    }
    public var owner: String
    public var name: String
    public var createdTime: String
    public var updatedTime: String
    public var id: String
    public var type: String
    public var password: String
    public var passwordSalt: String
    public var displayName: String
    public var firstName: String
    public var lastName: String
    public var avatar: String
    public var permanentAvatar: String
    public var email: String
    public var phone: String
    public var location: String
    public var address: [String]?
    public var affiliation: String
    public var title: String
    public var idCardType: String
    public var idCard: String
    public var homepage: String
    public var bio: String
    public var region: String
    public var language: String
    public var gender: String
    public var birthday: String
    public var education: String
    public var score: Int
    public var karma: Int
    public var ranking: Int
    public var isDefaultAvatar: Bool
    public var isOnline: Bool
    public var isAdmin: Bool
    public var isGlobalAdmin: Bool
    public var isForbidden: Bool
    public var isDeleted: Bool
    public var signupApplication: String
    public var hash: String
    public var preHash: String
    public var createdIp: String
    public var lastSigninTime: String
    public var lastSigninIp: String
    public var github: String
    public var google: String
    public var qq: String
    public var wechat: String
    public var facebook: String
    public var dingtalk: String
    public var weibo: String
    public var gitee: String
    public var linkedin: String
    public var wecom: String
    public var lark: String
    public var gitlab: String
    public var adfs: String
    public var baidu: String
    public var infoflow: String
    public var apple: String
    public var azuread: String
    public var slack: String
    public var steam: String
    public var ldap: String
    public var properties: [String:String]
    public var nonce: String
    public var scope: String
    public var iss: IssuerClaim
    public var sub: SubjectClaim
    public var aud: AudienceClaim
    public var exp: ExpirationClaim
    public var nbf: NotBeforeClaim
    public var iat: IssuedAtClaim
}

