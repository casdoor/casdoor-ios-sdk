//based on URLEncodedFormError.swift from vapor/vapor
// https://github.com/vapor/vapor/blob/main/Sources/Vapor/URLEncodedForm/URLEncodedFormError.swift

/// Errors thrown while encoding/decoding `application/x-www-form-urlencoded` data.
enum URLEncodedFormError: Error {
    case malformedKey(key: Substring)
}

extension URLEncodedFormError {
    var reason: String {
        switch self {
        case .malformedKey(let path):
            return "Malformed form-urlencoded key encountered: \(path)"
        }
    }
}
