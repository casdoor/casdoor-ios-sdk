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
public struct ContentConfiguration {
    public static var global: ContentConfiguration = .init()
    
    public static var dateFormatter:DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)
        return dateFormatter
    }()
    private init() {}
    public var josnDecoder: JSONDecoder {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .formatted(Self.dateFormatter)
        return jsonDecoder
    }
    public var jsonEncoder: JSONEncoder {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .formatted(Self.dateFormatter)
        return jsonEncoder
    }
    public var urlEncoder: URLEncodedFormEncoder {
        let encoder = URLEncodedFormEncoder.init(
            configuration: .init(
                dateEncodingStrategy: .custom{ date, encoder in
              var container = encoder.singleValueContainer()
                    try container.encode(DateFormatterFactory.threadSpecific.string(from: date))
        }))
        return encoder
    }
    public var urlDecoder: URLEncodedFormDecoder {
        let decoder = URLEncodedFormDecoder.init(
            configuration: .init(dateDecodingStrategy: .custom{ decoder in
                let container = try decoder.singleValueContainer()
                let string = try container.decode(String.self)
                guard let date = DateFormatterFactory.threadSpecific.date(from: string) else {
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode date from string '\(string)'")
                }
                return date
            }))
        return decoder
    }
}
