//
//  FeedsManager.swift
//  
//
//  Created by Nikhil Nigade on 07/03/21.
//

import Foundation
import Models
import DZNetworking
import CommonCrypto
import SwiftyJSON

#if os(macOS)
import AppKit
#else
import UIKit
#endif

enum FeedsManagerError : Error {
    case general(message: String)
}

public final class FeedsManager: NSObject {
    
    static let shared = FeedsManager()
    var deviceID: String?
    unowned var user: User?
    
    // MARK: - Sessions
    var session: DZURLSession {
        get {
            #if os(macOS)
            return mainSession
            #else
            return UIApplication.shared.applicationState == UIApplication.State.background ? backgroundSession : mainSession
            #endif
        }
    }
    
    lazy var mainSession: DZURLSession = {
        
        let sessionConfiguration = URLSessionConfiguration.default
        
        #if DEBUG
        sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        #else
        sessionConfiguration.requestCachePolicy = .useProtocolCachePolicy
        #endif
        
        sessionConfiguration.timeoutIntervalForRequest = 60.0
        sessionConfiguration.httpShouldSetCookies = false
        sessionConfiguration.httpCookieAcceptPolicy = .never
        sessionConfiguration.httpMaximumConnectionsPerHost = 10
        sessionConfiguration.httpCookieStorage = nil
        sessionConfiguration.allowsCellularAccess = true
        sessionConfiguration.waitsForConnectivity = false
        sessionConfiguration.shouldUseExtendedBackgroundIdleMode = true
        
        var additionalHeaders = [String: String]()
        
        additionalHeaders["Accept"] = "application/json"
        additionalHeaders["Content-Type"] = "application/json"
        additionalHeaders["Accept-Encoding"] = "gzip"
//        additionalHeaders["X-App-FullVersion"] = fullVersion
//        additionalHeaders["X-App-MajorVersion"] = majorVersion
        
        sessionConfiguration.httpAdditionalHeaders = additionalHeaders
        
        var s = DZURLSession(sessionConfiguration: sessionConfiguration)
        s.baseURL = URL(string: "http://192.168.1.90:3000")
//        s.baseURL = URL(string: "https://api.elytra.app")
        
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
            
            let timecode = "\(Date().timeIntervalSince1970)"
            let stringToSign = "\(userID)_\(uuid)_\(timecode)"
            
            let signature = stringToSign.hmac(key: uuid)
            
            r.addValue(signature, forHTTPHeaderField: "Authorization")
            r.addValue("1", forHTTPHeaderField: "x-userid")
            r.addValue("1", forHTTPHeaderField: "x-bypass")
            r.addValue(timecode, forHTTPHeaderField: "x-timestamp")
            
            if let deviceID = sself.deviceID {
                r.addValue(deviceID, forHTTPHeaderField: "x-device")
            }
            
            return r
            
        }
        
        return s
    }()
    
    lazy var backgroundSession: DZURLSession = {
        
        let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: "elytra.background")
        sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        sessionConfiguration.timeoutIntervalForRequest = 60.0
        sessionConfiguration.httpShouldSetCookies = false
        sessionConfiguration.httpCookieAcceptPolicy = .never
        sessionConfiguration.httpMaximumConnectionsPerHost = 2
        sessionConfiguration.httpCookieStorage = nil
        sessionConfiguration.allowsCellularAccess = true
        sessionConfiguration.waitsForConnectivity = false
        sessionConfiguration.isDiscretionary = false
        sessionConfiguration.shouldUseExtendedBackgroundIdleMode = true
        
        var additionalHeaders = [String: String]()
        
        additionalHeaders["Accept"] = "application/json"
        additionalHeaders["Content-Type"] = "application/json"
        additionalHeaders["Accept-Encoding"] = "gzip"
//        additionalHeaders["X-App-FullVersion"] = fullVersion
//        additionalHeaders["X-App-MajorVersion"] = majorVersion
        
        sessionConfiguration.httpAdditionalHeaders = additionalHeaders
        
        var s = DZURLSession(sessionConfiguration: sessionConfiguration)
        s.baseURL = URL(string: "http://192.168.1.90:3000")
//        s.baseURL = URL(string: "https://api.elytra.app")
        
        #if !DEBUG
        s.baseURL = URL(string: "https://api.elytra.app")
        #endif
        
        s.useOMGUserAgent = true
        s.responseParser = nil
        s.isBackgroundSession = true
        
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
            
            let timecode = "\(Date().timeIntervalSince1970)"
            let stringToSign = "\(userID)_\(uuid)_\(timecode)"
            
            let signature = stringToSign.hmac(key: uuid)
            
            r.addValue(signature, forHTTPHeaderField: "Authorization")
            r.addValue("1", forHTTPHeaderField: "x-userid")
            r.addValue("1", forHTTPHeaderField: "x-bypass")
            r.addValue(timecode, forHTTPHeaderField: "x-timestamp")
            
            if let deviceID = sself.deviceID {
                r.addValue(deviceID, forHTTPHeaderField: "x-device")
            }
            
            return r
            
        }
        
        return s
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

// MARK: - Users
extension FeedsManager {
    
    public func getUser(userID: String, completion:((Result<User?, Error>) -> Void)?) {
        
        guard userID.isEmpty == false else {
            completion?(.failure((NSError(domain: "Elytra", code: 501, userInfo: [NSLocalizedDescriptionKey: "An invalid or no authentication ID was provided."]) as Error)))
            return
        }
        
        let path = "/user"
        let query = [
            "userID": userID,
            "env": Bundle.main.configurationString
        ]
        
        session.GET(path: path, query: query, resultType: GetUserResult.self) { (result) in
            
            switch result {
            case .success(let (_, results)):
                guard let results = results else {
                    completion?(.failure((NSError(domain: "Elytra", code: 404, userInfo: [NSLocalizedDescriptionKey: "An inactive or no user was found."]) as Error)))
                    return
                }

                completion?(.success(results.user))

            case .failure(let error):
                completion?(.failure(error))
            }
            
        }
        
    }
    
    public func createUser(uuid: String, completion:((Result<User?, Error>) -> Void)?) {
        
        guard uuid.isEmpty == false else {
            completion?(.failure((NSError(domain: "Elytra", code: 501, userInfo: [NSLocalizedDescriptionKey: "An invalid or no authentication ID was provided."]) as Error)))
            return
        }
        
        let body = ["uuid": uuid]
        
        session.PUT(path: "/user", query: nil, body: body, resultType: GetUserResult.self) { (result) in
            
            switch result {
            case .success(let (_, results)):
                guard let results = results else {
                    completion?(.failure((NSError(domain: "Elytra", code: 404, userInfo: [NSLocalizedDescriptionKey: "An inactive or no user was found."]) as Error)))
                    return
                }

                completion?(.success(results.user))

            case .failure(let error):
                completion?(.failure(error))
            }
            
        }
        
    }
    
    public func startFreeTrial(completion:((Result<Subscription, Error>) -> Void)?) {
        
        let date = Date().addingTimeInterval(14 * 86400)
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        
        let expiry = formatter.string(from: date)
        
        let body = ["expiry": expiry]
        let query = ["env": Bundle.main.configurationString]
        
        session.PUT(path: "/1.7/trial", query: query, body: body, resultType: StartTrialResult.self) { [weak self] (result) in
            
            switch result {
            case .success(let (_, results)):
                guard let results = results else {
                    completion?(.failure((NSError(domain: "Elytra", code: 404, userInfo: [NSLocalizedDescriptionKey: "An invalid response was received."]) as Error)))
                    return
                }

                if results.status == true {
                    
                    // done
                    self?.getSubscription(completion: completion)
                    
                }
                else {
                    // we have an existing subscription
                    self?.getSubscription(completion: completion)
                    
                }

            case .failure(let error):
                completion?(.failure(error))
            }
            
        }
        
    }
    
    public func getSubscription(completion:((Result<Subscription, Error>) -> Void)?) {
        
        session.GET(path: "/store", query: nil, resultType: GetSubscriptionResult.self) { (result) in
            
            switch result {
            case .success(let (_, results)):
                guard let results = results else {
                    completion?(.failure((NSError(domain: "Elytra", code: 404, userInfo: [NSLocalizedDescriptionKey: "An invalid response was received."]) as Error)))
                    return
                }

                let subscription = results.subscription
                
                completion?(.success(subscription))

            case .failure(let error):
                completion?(.failure(error))
            }
            
        }
        
    }
    
}

extension FeedsManager {
    
    public func getFeeds(completion:((Result<GetFeedsResult, Error>) -> Void)?) {
        
        guard let user = user else {
            completion?(.failure((NSError(domain: "Elytra", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not logged in."]) as Error)))
            return
        }
        
        let query = [
            "userID": "\(user.userID!)",
            "version": "2.3"
        ]
        
        session.GET(path: "/feeds", query: query) { (result) -> Result<GetFeedsResult, Error> in
            
            switch result {
            case .success((_, let result)):
                guard let data = result else {
                    return Result.failure(FeedsManagerError.general(message: "Invalid or no data was received."))
                }
                
                do {
                    
                    let json = try JSON(data: data)
                    
                    let s = json["structure"]
                    
                    guard let f = json["feeds"].arrayObject,
                          let fo = s["folders"].arrayObject
                    else {
                        return Result.failure(FeedsManagerError.general(message: "Invalid data received."))
                    }

                    let feeds: [Feed] = f.map { Feed(from: ($0 as! [String: Any])) }
                    let folders: [Folder] = fo.map { Folder(from: $0 as! [String: Any]) }

                    let retval = GetFeedsResult(feeds: feeds, folders: folders)

                    return Result.success(retval)
                    
                }
                catch {
                    return Result.failure(error)
                }
            case .failure(let error):
                print(error)
            }
            
            return .failure(FeedsManagerError.general(message: "An unknown error occurred when fetching feeds."))
            
        } completion: { (result) in
            
            switch result {
            case .success((_, let result)):
                guard let result = result else {
                    completion?(.failure(FeedsManagerError.general(message: "No response received when fetching feeds")))
                    return
                }

                completion?(.success(result))

            case .failure(let error):
                completion?(.failure(error))
            }
            
        }

        
    }
    
}

extension String {
    
    public func hmac(key: String) -> String {
        
        let keyStr = key.cString(using: .utf8)
        let str = self.cString(using: .utf8)
        
        let keyLen = Int(key.lengthOfBytes(using: .utf8))
        let strLen = Int(self.lengthOfBytes(using: .utf8))
        
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: Int(CC_SHA256_DIGEST_LENGTH))
        
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyStr!, keyLen, str!, strLen, result)
        
        let digest = stringFromResult(result: result, length: Int(CC_SHA256_DIGEST_LENGTH))

        result.deallocate()

        return digest
   }
    
    private func stringFromResult(result: UnsafeMutablePointer<CUnsignedChar>, length: Int) -> String {
        let hash = NSMutableString()
        for i in 0..<length {
            hash.appendFormat("%02x", result[i])
        }
        return String(hash)
    }
    
}
