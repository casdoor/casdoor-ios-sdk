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

import AsyncHTTPClient
import Logging
import NIOConcurrencyHelpers
import NIOCore
import Dispatch
import NIOHTTP1
public final class CasdoorClient {
    public static let loggingDisabled = Logger(label: "Casdoor-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() })
    static let globalRequestID = NIOAtomic<Int>.makeAtomic(value: 0)
    let httpClient: EventLoopHTTPClient
    let httpClientProvider: HTTPClientProvider
    /// EventLoopGroup used by CasdoorClient
    public let eventLoopGroup: EventLoopGroup
    /// Logger used for non-request based output
    let clientLogger: Logger
    
    let options: Options
    
    
    private let isShutdown = NIOAtomic<Bool>.makeAtomic(value: false)
    
    public init(
        options: Options,
        httpClientProvider: HTTPClientProvider,
        logger clientLogger: Logger = CasdoorClient.loggingDisabled
    ) {
        self.httpClientProvider = httpClientProvider
        var _httpClient: HTTPClient
        switch httpClientProvider {
        case .shared(let providedHTTPClient):
            _httpClient = providedHTTPClient
        case .createNewWithEventLoopGroup(let elg):
            _httpClient = AsyncHTTPClient.HTTPClient(eventLoopGroupProvider: .shared(elg), configuration: .init(timeout: .init(connect: .seconds(10))))
        case .createNew:
            _httpClient = AsyncHTTPClient.HTTPClient(eventLoopGroupProvider: .createNew, configuration: .init(timeout: .init(connect: .seconds(10))))
        }
        self.eventLoopGroup = _httpClient.eventLoopGroup
        self.httpClient = _httpClient.delegating(to: eventLoopGroup.next(), logger: clientLogger, loggerLevel: options.requestLogLevel)
        self.clientLogger = clientLogger
        self.options = options
    }
    
    deinit {
        assert(self.isShutdown.load(), "CasdoorClient not shut down before the deinit. Please call client.shutdown() when no longer needed.")
    }
    
    public func shutdown(queue: DispatchQueue = .global(), _ callback: @escaping (Error?) -> Void) {
        guard self.isShutdown.compareAndExchange(expected: false, desired: true) else {
            callback(CasdoorError.alreadyShutdown)
            return
        }
        switch self.httpClientProvider {
        case .createNew, .createNewWithEventLoopGroup:
            self.httpClient.http.shutdown(queue: queue) { error in
                if let error = error {
                    self.clientLogger.log(level: self.options.errorLogLevel, "Error shutting down HTTP client", metadata: [
                        "casdoor-error": "\(error)",
                    ])
                }
                callback(error)
            }
            
        case .shared:
            callback(nil)
        }
    }
    
    public enum HTTPClientProvider {
        case shared(HTTPClient)
        
        case createNewWithEventLoopGroup(EventLoopGroup)
        
        case createNew
    }
    
    
    /// Additional options
    public struct Options {
        /// log level used for request logging
        let requestLogLevel: Logger.Level
        /// log level used for error logging
        let errorLogLevel: Logger.Level
        
        public init(
            requestLogLevel: Logger.Level = .debug,
            errorLogLevel: Logger.Level = .debug
        ) {
            self.requestLogLevel = requestLogLevel
            self.errorLogLevel = errorLogLevel
        }
    }
}
