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
    public var parametersFromQueryString: [String: String] {
        return dictionaryBySplitting("&", keyValueSeparator: "=")
    }
    
    fileprivate func dictionaryBySplitting(_ elementSeparator: String, keyValueSeparator: String) -> [String: String] {
           var string = self

           if hasPrefix(elementSeparator) {
               string = String(dropFirst(1))
           }

           var parameters = [String: String]()

           let scanner = Scanner(string: string)

           while !scanner.isAtEnd {
                   let key = scanner.scanUpToString(keyValueSeparator)
                   _ = scanner.scanString(keyValueSeparator)

                   let value = scanner.scanUpToString(elementSeparator)
                   _ = scanner.scanString(elementSeparator)

                   if let key = key {
                       if let value = value {
                           if key.contains(elementSeparator) {
                               var keys = key.components(separatedBy: elementSeparator)
                               if let key = keys.popLast() {
                                   parameters.updateValue(value, forKey: String(key))
                               }
                               for flag in keys {
                                   parameters.updateValue("", forKey: flag)
                               }
                           } else {
                               parameters.updateValue(value, forKey: key)
                           }
                       } else {
                           parameters.updateValue("", forKey: key)
                       }
                   }
               }
           return parameters
       }
}
