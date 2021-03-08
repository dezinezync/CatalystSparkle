//
//  FeedsManager.swift
//  
//
//  Created by Nikhil Nigade on 07/03/21.
//

import Foundation
import Models
import DZNetworking

enum FeedsManagerError : Error {
    case general(message: String)
}

public final class FeedsManager: NSObject {
    
    static let shared = FeedsManager()
    var deviceID: String?
    unowned var user: User?
    
//    private let baseURL = URL(string: "https://192.168.1.90:3000")!
    private let baseURL = URL(string: "https://api.elytra.app")!
    
    // MARK: - Users
    public func getUser(uuid: String, success:((_ user: User) -> Void)?, failure: ((_ error: Error) -> Void)?) {
        
        guard uuid.isEmpty == false else {
            failure?(NSError(domain: "Elytra", code: 501, userInfo: [NSLocalizedDescriptionKey: "An invalid or no authentication ID was provided."]) as Error)
            return
        }
        
        let url = baseURL.appendingPathComponent("/user")
        let query = [
            "uuid": uuid,
            "env": Bundle.main.configurationString
        ]
        
//        standardGET(url: url, query: query, resultType: GetUserResult.self) { (result) in
//
//            switch result {
//            case .success(let (_, results)):
//                guard let results = results else {
//                    failure?(NSError(domain: "Elytra", code: 404, userInfo: [NSLocalizedDescriptionKey: "An inactive or no user was found."]) as Error)
//                    return
//                }
//
//                success?(results.user)
//
//            case .failure(let error):
//                failure?(error)
//            }
//
//        }
        
    }
    
    // MARK: - Sessions
    
    
    lazy var mainSession: URLSession = {
        
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.requestCachePolicy = .useProtocolCachePolicy
        sessionConfiguration.timeoutIntervalForRequest = 60.0
        sessionConfiguration.httpShouldSetCookies = false
        sessionConfiguration.httpCookieAcceptPolicy = .never
        sessionConfiguration.httpMaximumConnectionsPerHost = 10
        sessionConfiguration.httpCookieStorage = nil
        sessionConfiguration.allowsCellularAccess = true
        sessionConfiguration.waitsForConnectivity = false
        
        var additionalHeaders = [String: String]()
        
        additionalHeaders["Accept"] = "application/json"
        additionalHeaders["Content-Type"] = "application/json"
        additionalHeaders["Accept-Encoding"] = "gzip"
//        additionalHeaders["X-App-FullVersion"] = fullVersion
//        additionalHeaders["X-App-MajorVersion"] = majorVersion
        
        sessionConfiguration.httpAdditionalHeaders = additionalHeaders
        
        var s = DZURLSession(sessionConfiguration: sessionConfiguration)
        s.baseURL = URL(string: "http://192.168.1.90:3000")
        s.baseURL = URL(string: "https://api.elytra.app")
        
        #if !DEBUG
        s.baseURL = URL(string: "https://api.elytra.app")
        #endif
        
        s.useOMGUserAgent = true
        s.responseParser = nil
        
        s.requestModifier = { [weak self] (request: NSMutableURLRequest?) -> NSMutableURLRequest? in
            
            guard let r = request else {
                return request
            }
            
            guard let sself = self else {
                return request
            }
            
            r.addValue("application/json", forHTTPHeaderField: "Accept")
            
            // compute Auth
            let userID = sself.user?.userID ?? 0
            let uuid = sself.user?.uuid ?? "x890371abdgvdfggsnnaa="
            
            let encoded = uuid.data(using: .utf8)?.base64EncodedString()
            let timecode = "\(Date().timeIntervalSince1970)"
            let stringToSign = "\(userID)_\(uuid)_\(timecode)"
            
            let signature = 
            
            return r
            
        }
        
        return URLSession(configuration: sessionConfiguration)
    }()
    
}

enum AppConfiguration: Int {
  case Debug
  case TestFlight
  case AppStore
}

extension Bundle {
    var appConfiguration: AppConfiguration {
        #if DEBUG
        return AppConfiguration.Debug
        #else
        
        guard let path = self.appStoreReceiptURL else {
            return AppConfiguration.Debug
        }
        
        if (path.path.contains("CoreSimulator") || path.path.contains("Debug-maccatalyst")) {
            return AppConfiguration.Debug
        }
        
        let isTestFlight = path.lastPathComponent == "sandboxReceipt"
        
        if (isTestFlight) {
            return AppConfiguration.TestFlight
        }
        return AppConfiguration.AppStore
        #endif
    }
    
    var configurationString: String {
        switch self.appConfiguration {
        case .Debug:
            return "Sandbox"
            
        case .TestFlight:
            return "ProductionSandbox"
            
        default:
            return "Production"
        }
    }
    
}

