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
| jwtSecret        | Yes  | Same as Casdoor JWT secret                         |
| apiEndpoint       | NO  | Casdoor Api Url, default endpoint + "/api/"   |
| organizationName | Yes  |Organization name
```swift
let jwtKey = "jwt secret"
let config:CasdoorConfig = .init(
            endpoint: "http://localhost:8000",
            clientID: "ced4d6db2f4644b85a75",
            organizationName: "organization_6qvtvh",
            redirectUri: "http://localhost:9000/callback",
            appName: "application_y38644",
            jwtSecret: jwtKey.data(using: .utf8)!
     )
```
## Step2. Init CasdoorClient
This package use AsyncHTTPClient as HTTPClient.
AsyncHTTPClient is Asynchronous and non-blocking.
If your application does not use SwiftNIO yet, it is acceptable to use `httpClientProvider: .createNew` but please make sure to share the returned `HTTPClient` instance throughout your whole application. Do not create a large number of `HTTPClient` instances with `httpClientProvider: .createNew`, this is very wasteful and might exhaust the resources of your program.
```swift
let client = CasdoorClient.init(options: .init(requestLogLevel: .info, errorLogLevel: .debug), httpClientProvider: .createNew, logger: .init(label: "casdoor-test"))
```
## Step3. Init Casdoor
The Casdoor Contains all APIs
```swift
let casdoor:Casdoor = .init(client:client,config:config)
```
## Step4. Authorize with the Casdoor server
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
listen to the response from `Casdoor`. For example, if your `redirect_uri` is `https://forum.casbin.com/callback`, then Casdoor will send a request to this URL along with two parameters `code` and `state`, which will be used in later steps for authentication. 
2. `state` is usually your Application's name, you can find it under the `Applications` tab in `Casdoor`, and the leftmost `Name` column gives each application's name.
3. After Casdoor verification passed, it will be redirected to your `redirect_uri`, like `http://localhost:9000/callback?code=xxx&state=yyyy`.you can catch it in WKNavigationDelegate,get the `code` and `state`, then call `requestOauthAccessToken(code:,state:)` and parse out jwt token.

``` swift
struct Code:Decodable {
    let code: String
}
extension OauthWebView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url ,url.absoluteString.hasPrefix("http://localhost:9000/callback")
        {
            decisionHandler(.cancel)
            let uri = URI.init(string: url.absoluteString)
            let code = try uri.decode(Code.self)
            self.casdoor
                .requestOauthAccessToken(code: code.code)
                .whenSuccess { tokenRes in
                  do {
                   //verify and parse jwt token
                   let user =  try self.casdoor.varifyToken(token:tokenRes.accessToken)
                   // save token
                       ....
                   } catch  {
                        ...    
                   }
                }
            self.navigationController?.popViewController(animated: true)
        }
        decisionHandler(.allow)
    }
}
```

