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

public struct AccessTokenResponse: Decodable, Sendable {
    public let accessToken: String
    public let idToken: String?
    public let refreshToken: String?
    public let tokenType: String
    public let expiresIn: Int
    public let scope: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case idToken = "id_token"
        case tokenType = "token_type"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case scope
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        idToken = try container.decodeIfPresent(String.self, forKey: .idToken)
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        tokenType = try container.decodeIfPresent(String.self, forKey: .tokenType) ?? ""
        expiresIn = try container.decodeIfPresent(Int.self, forKey: .expiresIn) ?? 0
        scope = try container.decodeIfPresent(String.self, forKey: .scope) ?? ""
    }
}

/// Response of `/api/userinfo`. Groups, roles and permissions are only returned when the
/// token was issued with the "profile" scope and the application allows those fields.
public struct CasdoorUserInfo: Decodable, Sendable {
    /// User id
    public let sub: String
    public let iss: String?
    public let aud: String?
    /// Username (`preferred_username`)
    public let name: String?
    /// Display name (`name`)
    public let displayName: String?
    public let email: String?
    public let emailVerified: Bool
    /// Avatar URL (`picture`)
    public let avatar: String?
    public let address: String?
    public let phone: String?
    public let realName: String?
    public let isVerified: Bool
    public let groups: [String]
    public let roles: [String]
    public let permissions: [String]

    enum CodingKeys: String, CodingKey {
        case sub, iss, aud, email, address, phone, groups, roles, permissions
        case name = "preferred_username"
        case displayName = "name"
        case emailVerified = "email_verified"
        case avatar = "picture"
        case realName = "real_name"
        case isVerified = "is_verified"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sub = try container.decodeIfPresent(String.self, forKey: .sub) ?? ""
        iss = try container.decodeIfPresent(String.self, forKey: .iss)
        // "aud" may be a string or an array of strings
        if let aud = try? container.decodeIfPresent(String.self, forKey: .aud) {
            self.aud = aud
        } else {
            self.aud = (try? container.decodeIfPresent([String].self, forKey: .aud))?.first
        }
        name = try container.decodeIfPresent(String.self, forKey: .name)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        emailVerified = try container.decodeIfPresent(Bool.self, forKey: .emailVerified) ?? false
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        realName = try container.decodeIfPresent(String.self, forKey: .realName)
        isVerified = try container.decodeIfPresent(Bool.self, forKey: .isVerified) ?? false
        groups = try container.decodeIfPresent([String].self, forKey: .groups) ?? []
        roles = try container.decodeIfPresent([String].self, forKey: .roles) ?? []
        permissions = try container.decodeIfPresent([String].self, forKey: .permissions) ?? []
    }
}
