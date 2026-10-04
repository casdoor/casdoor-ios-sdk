# casdoor-ios-sdk

<p align="center">
  <a href="#badge">
    <img alt="semantic-release" src="https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg">
  </a>
  <a href="https://github.com/casdoor/casdoor-ios-sdk/actions/workflows/ci.yml">
    <img alt="GitHub Workflow Status (branch)" src="https://img.shields.io/github/actions/workflow/status/casdoor/casdoor-ios-sdk/ci.yml?branch=master">
  </a>
  <a href="https://github.com/casdoor/casdoor-ios-sdk/releases/latest">
    <img alt="GitHub Release" src="https://img.shields.io/github/v/release/casdoor/casdoor-ios-sdk.svg">
  </a>
</p>

Casdoor's SDK for iOS, macOS, tvOS and watchOS. It signs users in with the OAuth 2.0 authorization code flow with PKCE, so the app does not need a client secret. No third-party dependencies.

## Install

Swift Package Manager:

```swift
.package(url: "https://github.com/casdoor/casdoor-ios-sdk.git", from: "1.0.0")
```

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "Casdoor", package: "casdoor-ios-sdk")
    ]
),
```

## Configure

| Name             | Required | Description                                                         |
| ---------------- | -------- | ------------------------------------------------------------------- |
| endpoint         | Yes      | Casdoor server URL, such as `https://door.casdoor.com`              |
| clientID         | Yes      | Client ID of the Casdoor application                                |
| organizationName | Yes      | Organization name                                                   |
| redirectUri      | Yes      | Callback URL, such as `casdoor://callback`; add it to the application's Redirect URLs |
| appName          | Yes      | Application name, used as the default `state`                       |
| apiEndpoint      | No       | Casdoor API URL, default `endpoint + "/api/"`                       |

```swift
import Casdoor

let casdoor = Casdoor(config: CasdoorConfig(
    endpoint: "http://localhost:8000",
    clientID: "ced4d6db2f4644b85a75",
    organizationName: "organization_6qvtvh",
    redirectUri: "casdoor://callback",
    appName: "application_y38644"
))
```

Keep one `Casdoor` instance for the whole sign-in: `getSigninUrl()` stores the PKCE code verifier, state and nonce that `handleCallback(url:)` checks afterwards.

## Sign in

```swift
import AuthenticationServices

let signinUrl = try casdoor.getSigninUrl()   // scope defaults to "openid profile email"
let session = ASWebAuthenticationSession(url: signinUrl, callbackURLScheme: "casdoor") { callbackUrl, error in
    guard let callbackUrl = callbackUrl else { return }
    Task {
        let token = try await casdoor.handleCallback(url: callbackUrl)
        // token.accessToken, token.idToken, token.refreshToken
    }
}
session.presentationContextProvider = self
session.start()
```

`handleCallback(url:)` checks `state`, exchanges the code at `/api/login/oauth/access_token` and checks the `nonce` in the ID token. If you parse the callback URL yourself, call `requestOauthAccessToken(code:)` instead.

`getSignupUrl()` works the same way and opens the sign-up page.

## User info, roles and permissions

```swift
let user = try await casdoor.getUserInfo(accessToken: token.accessToken)
print(user.name, user.email, user.roles, user.permissions, user.groups)
```

Roles, permissions and groups are returned when the token has the `profile` scope.

To read claims of the ID token (the signature is not verified):

```swift
let claims = try Casdoor.decodeJwtPayload(token.idToken!)
```

## Refresh the token

```swift
let newToken = try await casdoor.renewToken(refreshToken: token.refreshToken!)
```

## Sign out

There are two ways, use one of them:

1. Only end the tokens (no UI). The Casdoor session cookie in the sign-in browser stays, so the next sign-in may not ask for the password:

   ```swift
   try await casdoor.logout(idToken: token.idToken!)
   ```

2. End the tokens and the browser session. Open the sign-out URL in `ASWebAuthenticationSession`; Casdoor redirects back to `redirectUri` when done:

   ```swift
   let signoutUrl = try casdoor.getSignoutUrl(idToken: token.idToken!)
   let session = ASWebAuthenticationSession(url: signoutUrl, callbackURLScheme: "casdoor") { _, _ in }
   session.presentationContextProvider = self
   session.start()
   ```

Then delete the tokens stored in the app.

## Errors

All methods throw `CasdoorError`; switch on `error.kind`:

| Kind                         | Meaning                                                                 |
| ---------------------------- | ----------------------------------------------------------------------- |
| `.responseMessage(msg)`      | Casdoor API error, e.g. `Token not found, invalid accessToken`           |
| `.oauth(error, description)` | OAuth error, e.g. `invalid_grant`, or `access_denied` in the callback    |
| `.invalidResponse(code, body)` | The response is not JSON, usually a wrong `endpoint` / `apiEndpoint`  |
| `.invalidCallback(msg)`      | The callback URL has no code or the state does not match                 |
| `.invalidJwt(msg)`           | The ID token cannot be decoded or its nonce does not match               |
| `.missingCodeVerifier`       | The code was exchanged without calling `getSigninUrl()` on this instance |
| `.invalidURL`                | A URL built from the config is malformed                                 |

## Example

See https://github.com/casdoor/casdoor-ios-example
