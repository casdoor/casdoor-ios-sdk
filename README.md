# casdoor-ios-sdk
Casdoor's SDK for iOS will allow you to easily connect your application to the Casdoor authentication system without having to implement it from scratch.
Casdoor SDK is simple to use. We will show you the steps below.
## Step0. Adding the dependency
```swift
.package(url: "https://github.com/casdoor/casdoor-ios-sdk.git", from: "x.x.x")
```
and Casdoor dependency to your target:
```swift
.target(
   name: "MyApp", 
   dependencies: [
       .product(name: "Casdoor", package: "casdoor-ios-sdk")
    ]
 ),
```
## Step1. Init Config
Initialization requires 5 parameters, which are all str type:
| Name (in order)  | Must | Description                                         |
| ---------------- | ---- | --------------------------------------------------- |
| endpoint         | Yes  | Casdoor Server Url, such as `http://localhost:8000` |
| clientID         | Yes  | Application.clientID                              |
| appName           | Yes  | Application.name                           |
| apiEndpoint       | NO  | Casdoor Api Url, default endpoint + "/api/"   |
| organizationName | Yes  |Organization name
```swift
let config:CasdoorConfig = .init(
            endpoint: "http://localhost:8000",
            clientID: "ced4d6db2f4644b85a75",
            organizationName: "organization_6qvtvh",
            redirectUri: "casdoor://callback",
            appName: "application_y38644",
     )
```
## Step2. Init Casdoor
The Casdoor Contains all APIs
```swift
let casdoor:Casdoor = .init(config:config)
```
## Step3. Authorize with the Casdoor server
At this point, we should use some ways to verify with the Casdoor server.  

To start, we want you understand clearly the verification process of Casdoor.
The following paragraphs will mention your app that wants to use Casdoor as a means
of verification as `APP`, and Casdoor as `Casdoor`.
`APP` will send a request to `Casdoor`. Since `Casdoor` is a UI-based OAuth
   provider, you cannot use request management service like Postman to send a URL
   with parameters and get back a JSON file.  

casdoor-ios-sdk support the url,you can use in webview or safariView
```swift
casdoor.getSigninUrl(scope:nil,state:nil)
```
Hints:
1. `redirect_uri` is the URL that your `APP` is configured to
listen to the response from `Casdoor`. For example, if your `redirect_uri` is `casdoor://callback`, then Casdoor will send a request to this URL along with two parameters `code` and `state`, which will be used in later steps for authentication. 
2. `state` is usually your Application's name, you can find it under the `Applications` tab in `Casdoor`, and the leftmost `Name` column gives each application's name.
3. The authorize URL allows the user to connect to a provider and give access to your application.You can use WKWebView,SFSafariViewController or ASWebAuthenticationSession if you want.
4. After Casdoor verification passed, it will be redirected to your `redirect_uri`, like `casdoor://callback?code=xxx&state=yyyy`.you can catch it and get the `code` and `state`, then call `requestOauthAccessToken(code:,state:)` and parse out jwt token. 

# Example
See at: https://github.com/casdoor/casdoor-ios-example

