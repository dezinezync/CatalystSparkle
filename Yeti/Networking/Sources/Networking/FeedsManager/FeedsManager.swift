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

public enum FeedsManagerError : Error {
    
    case general(message: String)
    
    public var message: String? {
        return String(describing: self).replacingOccurrences(of: "general(message: \"", with: "").replacingOccurrences(of: "\")", with: "")
    }
    
    static public func from(description: String, statusCode: Int) -> NSError {
        
        return NSError(domain: "Elytra", code: statusCode, userInfo: [NSLocalizedDescriptionKey: description])
        
    }
    
}

@objcMembers public final class FeedsManager: NSObject {
    
    public static let shared = FeedsManager()
    public var deviceID: String?
    public unowned var user: User?
    
    public var fullVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    public var majorVersion: String {
        return fullVersion.components(separatedBy: ".").first!
    }
    
    public var pushToken: String? {
        didSet {
            if pushToken != nil {
                onSetPushToken()
            }
        }
    }
    
    public weak var subsribeAfterPushEnabled: Feed?
    
    // MARK: - Sessions
    public var session: DZURLSession {
        get {
            #if os(macOS)
            return mainSession
            #else
            var S: DZURLSession = mainSession
            
            if Thread.isMainThread == true {
                S = UIApplication.shared.applicationState != UIApplication.State.active ? backgroundSession : mainSession
            }
            else {
                let s = DispatchSemaphore(value: 0)
                
                DispatchQueue.main.async { [weak self] in
                    S = (UIApplication.shared.applicationState != UIApplication.State.active ? self?.backgroundSession : self?.mainSession)!
                    s.signal()
                }
                
                s.wait()
            }
            
            return S
            
            #endif
        }
    }
    
    public lazy var mainSession: DZURLSession = {
        
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
        
        var additionalHeaders: [String: String] = [:]
        
        additionalHeaders["Accept"] = "application/json"
        additionalHeaders["Content-Type"] = "application/json"
        additionalHeaders["Accept-Encoding"] = "gzip"
        additionalHeaders["X-App-FullVersion"] = fullVersion
        additionalHeaders["X-App-MajorVersion"] = majorVersion
        
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
            
            let key = uuid.data(using: .utf8)?.base64EncodedString(options: .endLineWithLineFeed)
            
            let timecode = "\(Date().timeIntervalSince1970)"
            let stringToSign = "\(userID)_\(uuid)_\(timecode)"
            
            let signature = stringToSign.hmac(key: key!)
            
            r.addValue(signature, forHTTPHeaderField: "Authorization")
            r.addValue("\(userID)", forHTTPHeaderField: "x-userid")
            
//            r.addValue("1", forHTTPHeaderField: "x-bypass")
            r.addValue(timecode, forHTTPHeaderField: "x-timestamp")
            
            if let deviceID = sself.deviceID {
                r.addValue(deviceID, forHTTPHeaderField: "x-device")
            }
            
            return r
            
        }
        
        return s
    }()
    
    public lazy var backgroundSession: DZURLSession = {
        
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
        
        var additionalHeaders: [String: String] = [:]
        
        additionalHeaders["Accept"] = "application/json"
        additionalHeaders["Content-Type"] = "application/json"
        additionalHeaders["Accept-Encoding"] = "gzip"
        additionalHeaders["X-App-FullVersion"] = fullVersion
        additionalHeaders["X-App-MajorVersion"] = majorVersion
        
        sessionConfiguration.httpAdditionalHeaders = additionalHeaders
        
        var s = DZURLSession(sessionConfiguration: sessionConfiguration)
        
        s.baseURL = URL(string: "http://192.168.1.90:3000")
        s.baseURL = URL(string: "https://api.elytra.app")
        
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
            
            let key = uuid.data(using: .utf8)?.base64EncodedString(options: .endLineWithLineFeed)
            
            let timecode = "\(Date().timeIntervalSince1970)"
            let stringToSign = "\(userID)_\(uuid)_\(timecode)"
            
            let signature = stringToSign.hmac(key: key!)
            
            r.addValue(signature, forHTTPHeaderField: "Authorization")
            r.addValue("\(userID)", forHTTPHeaderField: "x-userid")
//            r.addValue("1", forHTTPHeaderField: "x-bypass")
            r.addValue(timecode, forHTTPHeaderField: "x-timestamp")
            
            if let deviceID = sself.deviceID {
                r.addValue(deviceID, forHTTPHeaderField: "x-device")
            }
            
            return r
            
        }
        
        return s
    }()
    
}

public enum AppConfiguration: Int {
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
        
        session.GET(path: path, query: query) { (result) -> Result<GetUserResult, Error> in
            
            switch result {
            case .success((_, let result)):
                guard let data = result else {
                    return Result.failure(FeedsManagerError.from(description: "Invalid or no data was received.", statusCode: 500))
                }
                
                do {
                    
                    let json = try JSON(data: data)
                    
                    guard let s = json["user"].dictionaryObject
                    else {
                        return Result.failure(FeedsManagerError.general(message: "Invalid data received."))
                    }

                    let user = User(from: s)

                    let retval = GetUserResult(user: user)

                    return Result.success(retval)
                    
                }
                catch {
                    return Result.failure(error)
                }
                
            case .failure(let error):
                print(error)
                return Result.failure(error)
            }
            
        } completion: { result in
            
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
            case .success(_):
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    
                    // done
                    self?.getSubscription(completion: completion)
                    
                }

            case .failure(let error):
                completion?(.failure(error))
            }
            
        }
        
    }
    
    public func getSubscription(completion:((Result<Subscription, Error>) -> Void)?) {
        
        let query = ["env": Bundle.main.configurationString]
        
        session.GET(path: "/store", query: query, resultType: GetSubscriptionResult.self) { (result) in
            
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
    
    public func postAppReceipt(_ receipt: Data, completion:((Result<Subscription, Error>) -> Void)?) {
        
        guard let _ = user else {
            completion?(.failure(FeedsManagerError.from(description: "Session not active", statusCode: 401)))
            return
        }
        
        let receiptString = receipt.base64EncodedString()
        
        let query = [
            "userID": "\(user!.userID!)",
            "env": Bundle.main.configurationString
        ]
        
        session.POST(path: "/1.1/store", query: query, body: ["receipt": receiptString]) { (result) -> Result<Subscription, Error> in
            
            switch result {
            case .success((_, let result)):
                guard let data = result else {
                    return Result.failure(FeedsManagerError.from(description: "Invalid or no data was received.", statusCode: 500))
                }
                
                do {
                    
                    let json = try JSON(data: data)
                    
                    guard let s = json["subscription"].dictionaryObject
                    else {
                        return Result.failure(FeedsManagerError.general(message: "Invalid data received."))
                    }

                    let sub = Subscription(from: s)

                    return Result.success(sub)
                    
                }
                catch {
                    return Result.failure(error)
                }
                
            case .failure(let error):
                print(error)
                return Result.failure(error)
            }
            
        } completion: { result in
            
            switch result {
            case .failure(let error):
                completion?(.failure(error))
            case .success(let (_, sub)):
                completion?(.success(sub!))
            }
            
        }

        
    }
    
    public func deactivateAccount(completion:((Result<Bool, Error>) -> Void)?) {
        
        session.POST(path: "/1.4/\(user!.uuid!)/deactivate", query: [:], body: [:], resultType: [String: Bool].self) { result in
            
            switch result {
            
            case .failure(let error):
                completion?(.failure(error))
                
            case .success(let (_, result)):
                // assume it worked!
                let status = result?["status"] ?? true
                
                completion?(.success(status))
            
            }
            
        }
        
    }
    
}

// MARK: - Feeds
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
                return Result.failure(error)
            }
            
        } completion: { (result) in
            
            switch result {
            case .success((_, let result)):
                guard let result = result else {
                    completion?(.failure(FeedsManagerError.from(description: "No response received when fetching feeds", statusCode: 500)))
                    return
                }

                completion?(.success(result))

            case .failure(let error):
                completion?(.failure(error))
            }
            
        }

        
    }
    
    public func add(feed stub: [String: AnyHashable], completion:((Result<Feed, Error>) -> Void)?) {
        
        guard let _ = user else {
            completion?(.failure((NSError(domain: "Elytra", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not logged in."]) as Error)))
            return
        }
        
        session.PUT(path: "/2.3/feed", query: nil, body: stub, resultType: Feed.self) { [weak self] (result) in
            
            switch result {
            case .success(let (response, feed)): do {
                
                guard let response = response else {
                    completion?(.failure(FeedsManagerError.from(description: "No response recevied when trying to add the feed.", statusCode: 500)))
                    return
                }
                
                if response.statusCode == 300 {
                    
                    // multiple options
                    completion?(.failure(FeedsManagerError.from(description: "Not a supported URL.", statusCode: 400)))
                    return
                    
                }
                else if response.statusCode == 302 {
                    // already exists.
                    if let reroute = response.allHeaderFields["location"] as? String,
                       let url = URL(string: reroute) {
                        
                        let feedID = UInt((url.lastPathComponent as NSString).integerValue)
                        
                        self?.add(feed: feedID, completion: completion)
                        
                        return
                        
                    }
                    
                }
                else if response.statusCode == 304 {
                    // feed already exists in the user's list.
                    completion?(.failure(FeedsManagerError.general(message: "Feed already exists in your list.")))
                    return
                }
                
                guard let feed = feed else {
                    completion?(.failure(FeedsManagerError.general(message: "An unknown error occurred when adding this feed to your account")))
                    return
                }
                
                feed.unread = 0
                
                completion?(.success(feed))
                
            }
            case .failure(let error):
                completion?(.failure(error))
            }
            
        }
        
    }
    
    public func add(feed id: UInt, completion:((Result<Feed, Error>) -> Void)?) {
        
        guard let user = user else {
            completion?(.failure((NSError(domain: "Elytra", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not logged in."]) as Error)))
            return
        }
        
        let query = ["version": "2"]
        let body = [
            "feedID": "\(id)",
            "userID": "\(user.userID!)"
        ]
        
        session.PUT(path: "/feed", query: query, body: body, resultType: Feed.self) { (result) in
            
            switch result {
            case .success(let (response, feed)): do {
                
                guard let response = response else {
                    completion?(.failure(FeedsManagerError.from(description: "No response recevied when trying to add the feed.", statusCode: 500)))
                    return
                }
                
               if response.statusCode == 304 {
                    // feed already exists in the user's list.
                    completion?(.failure(FeedsManagerError.from(description: "Feed already exists in your list.", statusCode: 400)))
                    return
                }
                
                guard let feed = feed else {
                    completion?(.failure(FeedsManagerError.from(description: "An unknown error occurred when adding this feed to your account", statusCode: 500)))
                    return
                }
                
                feed.unread = 0
                
                completion?(.success(feed))
                
            }
            case .failure(let error):
                completion?(.failure(error))
            }
            
        }
        
    }
    
    public func delete(feed id: UInt, completion:((Result<Bool, Error>) -> Void)?) {
        
        guard let _ = user else {
            completion?(.failure((NSError(domain: "Elytra", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not logged in."]) as Error)))
            return
        }
        
        let path = "/feeds/\(id)"
        
        session.DELETE(path: path, query: nil, resultType: [String: Bool].self) { (result) in
            
            switch result {
            case .success(let (response, result)): do {
                
                guard (result?["status"] ?? false) == true else {
                    completion?(.failure(NSError(domain: "FeedsManager", code: response?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "An unknown error occurred when removing this feed from your account"])))
                    return
                }
                
                completion?(.success(true))
                
            }
            case .failure(let error):
                completion?(.failure(error))
            }
            
        }
        
    }
    
    public func rename(feed id: UInt, title: String, completion:((Result<Bool, Error>) -> Void)?) {
        
        session.POST(path: "/1.2/customFeed", query: [:], body: ["title": title, "feedID": id], resultType: [String: Bool].self) { result in
            
            switch result {
            case .failure(let error):
                completion?(.failure(error))
                
            case .success(let (_, result)):
                completion?(.success(result?["status"] ?? true))
            }
            
        }
        
    }
    
}

// MARK: - Folders
extension FeedsManager {
    
    public func add(folder title: String, completion:((Result<Folder, Error>) -> Void)?) {
        
        guard let _ = user else {
            completion?(.failure(FeedsManagerError.from(description: "User is not logged in", statusCode: 401)))
            return
        }
        
        session.PUT(path: "/folder", query: nil, body: ["title": title], resultType: [String: Folder].self) { result in
            
            switch result {
            case .failure(let error):
                completion?(.failure(error))
            case .success(let (_, retval)):
                guard let folder = retval?["folder"] else {
                    completion?(.failure(FeedsManagerError.from(description: "An invalid or no response was received", statusCode: 500)))
                    return
                }
                
                completion?(.success(folder))
            }
            
        }
        
    }
    
    public func update(folder id: UInt, title: String?, add: [UInt]?, delete: [UInt]?, completion:((Result<Bool, Error>) -> Void)?) {
        
        guard let _ = user else {
            completion?(.failure(FeedsManagerError.from(description: "User is not logged in", statusCode: 401)))
            return
        }
        
        var body: [String: AnyHashable] = [
            "folderID": id
        ]
        
        if title != nil {
            body["title"] = title!
        }
        
        if add != nil, add!.count > 0 {
            body["add"] = add.map { "\($0)" }
        }
        
        if delete != nil, delete!.count > 0 {
            body["del"] = delete.map { "\($0)" }
        }
        
        session.POST(path: "/folder", query: nil, body: body, resultType: [String: Bool].self) { result in
            
            switch result {
            case .failure(let error):
                completion?(.failure(error))
                
            case .success(let (_, result)):
                guard let result = result else {
                    completion?(.failure(FeedsManagerError.from(description: "An invalid or no response was received", statusCode: 500)))
                    return
                }
                
                completion?(.success(result["status"] ?? false))
            }
            
        }
        
    }
    
    public func delete(folder id: UInt, completion:((Result<Bool, Error>) -> Void)?) {
        
        guard let _ = user else {
            completion?(.failure(FeedsManagerError.from(description: "User is not logged in", statusCode: 401)))
            return
        }
        
        let path = "/folder"
        
        session.DELETE(path: path, query: ["folderID": "\(id)"], resultType: [String: Bool].self) { (result) in
            
            switch result {
            case .success(_): do {
                
                completion?(.success(true))
                
            }
            case .failure(let error):
                completion?(.failure(error))
            }
            
        }
        
    }
    
}


// MARK: - Articles
extension FeedsManager {
    
    public func getArticle(_ identifier: String, completion: ((Result<Article, Error>) -> Void)?) {
        
        session.GET(path: "/article/\(identifier)", query: nil) { result -> Result<Article, Error> in
            
            switch result {
            case .success((_, let result)):
                guard let data = result else {
                    return Result.failure(FeedsManagerError.from(description: "Invalid or no data was received.", statusCode: 500))
                }
                
                do {
                    
                    let json = try JSON(data: data)
                    
                    guard let s = json.dictionaryObject
                    else {
                        return Result.failure(FeedsManagerError.general(message: "Invalid data received."))
                    }

                    let article = Article(from: s)

                    return Result.success(article)
                    
                }
                catch {
                    return Result.failure(error)
                }
                
            case .failure(let error):
                print(error)
                return Result.failure(error)
            }
            
        } completion: { result in
            
            switch result {
            case .success(let (res, article)):
                guard let article = article else {
                    completion?(.failure(FeedsManagerError.from(description: "An unknown error occurred when fetching this article.", statusCode: res?.statusCode ?? 500)))
                    return
                }
                
                completion?(.success(article))
                
            case .failure(let error):
                completion?(.failure(error))
            }
            
        }
        
    }
    
    public func getArticles(forFeed feed:Feed, page: UInt = 1, completion:((Result<[Article], Error>) -> Void)?) {
        
        getArticles(forFeed: feed.feedID, page: page, completion: completion)
        
    }
    
    public func getArticles(forFeed feedID:UInt, page: UInt = 1, completion:((Result<[Article], Error>) -> Void)?) {
        
        guard feedID > 0 else {
            completion?(.failure(FeedsManagerError.general(message: "Invalid or no Feed ID was provided.")))
            return
        }
        
        session.GET(path: "/2.2/feeds/\(feedID)", query: ["page":"\(page)"]) { result -> Result<[Article],Error> in
            
            switch result {
            case .success((_, let result)):
                guard let data = result else {
                    return Result.failure(FeedsManagerError.from(description: "Invalid or no data was received.", statusCode: 500))
                }
                
                do {
                    
                    let json = try JSON(data: data)
                    
                    guard let s = json.dictionaryObject?["articles"] as? [[String: Any]]
                    else {
                        return Result.failure(FeedsManagerError.general(message: "Invalid data received."))
                    }

                    let articles = s.map { Article(from: $0) }

                    return Result.success(articles)
                    
                }
                catch {
                    return Result.failure(error)
                }
                
            case .failure(let error):
                print(error)
                return Result.failure(error)
            }
            
        } completion: { result in
            
            switch result {
            case .success(let (_, aResult)):
                let a = aResult ?? []
                completion?(.success(a))
            case .failure(let error):
                completion?(.failure(error))
            }
            
        }
        
    }
    
    public func getFullTextFor(_ articleID: String, completion:((Result<Article, Error>) -> Void)?) {
        
        session.GET(path: "/2.2/mercurial/\(articleID)", query: nil) { (result) -> Result<Article, Error> in
            
            switch result {
            case .success((_, let result)):
                guard let data = result else {
                    return Result.failure(FeedsManagerError.from(description: "Invalid or no data was received.", statusCode: 500))
                }
                
                do {
                    
                    let json = try JSON(data: data)
                    
                    guard let s = json.dictionaryObject
                    else {
                        return Result.failure(FeedsManagerError.general(message: "Invalid data received."))
                    }

                    let article = Article(from: s)

                    return Result.success(article)
                    
                }
                catch {
                    return Result.failure(error)
                }
                
            case .failure(let error):
                print(error)
                return Result.failure(error)
            }
            
        } completion: { result in
            
            switch result {
            case .success(let (res, article)):
                if let article = article {
                    completion?(.success(article))
                }
                else {
                    completion?(.failure(FeedsManagerError.from(description: "Failed to extract full text due to an unknown error.", statusCode: res?.statusCode ?? 500)))
                }
                
            case .failure(let error):
                completion?(.failure(error))
            }
            
        }
        
    }
    
    public func markRead(_ read: Bool, items: [Article], completion:((Result<[MarkReadItem], Error>) -> Void)?) {
        
        let limit: UInt = 100
        var anyError: Error?
        
        // mark in batches of 100
        guard items.count <= limit else {
            
            var counter: UInt = 0
            let total: UInt = UInt(items.count)
            
            var retval: [MarkReadItem] = []
            
            while (counter < total) {
                
                let inLimit = (counter + limit) > total ? (total - counter) : limit
                
                let subarray = Array(items[Int(counter)..<Int(counter + inLimit)])
                
                let semaphore = DispatchSemaphore(value: 0)
                
                markRead(read, items: subarray) { result in
                    
                    switch result {
                    case .failure(let error):
                        print(error)
                    case .success(let result):
                        retval.append(contentsOf: result)
                        print("Done iteration in \(counter)...\(inLimit)")
                    }
                    
                    semaphore.signal()
                    
                }
                
                semaphore.wait()
                
                counter += limit
                
            }
            
            if retval.count == 0 && total > 0 {
                
                DispatchQueue.main.async {
                    if let error = anyError {
                        completion?(.failure(error))
                    }
                    else {
                        completion?(.failure(FeedsManagerError.from(description: "An error occurred when marking read", statusCode: 500)))
                    }
                }
                
                return
            }
            
            DispatchQueue.main.async {
                completion?(.success(retval))
            }
            
            return
        }
        
        let identifiers = items.map { $0.identifier }
        
        guard identifiers.count > 0 else {
            return
        }
        
        let path = "/article/\(read ? "true" : "false")"
        let body = [
            "articles": identifiers
        ]
        
        session.POST(path: path, query: nil, body: body, resultType: [MarkReadItem].self) { (result) in
            
            switch result {
            
            case .failure(let error):
                anyError = error
                
                DispatchQueue.main.async {
                    completion?(.failure(error))
                }
            
            case .success((_, let result)):
                
                guard let r = result else {
                    let error = NSError(domain: "FeedsManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "An unknown error occurred and no response was received."])
                    
                    completion?(.failure(error as Error))
                    
                    return
                }
                
                DispatchQueue.main.async {
                    completion?(.success(r))
                }
                
            }
            
        }
        
    }
    
    public func mark(_ bookmark: Bool, item: Article, completion:((Result<MarkBookmarkItem, Error>) -> Void)?) {
        
        let path = "/article/\(item.identifier!)/bookmark"
        let body = [
            "bookmark": bookmark
        ]
        
        session.POST(path: path, query: nil, body: body, resultType: MarkBookmarkItem.self) { (result) in
            
            switch result {
            
            case .failure(let error):
                completion?(.failure(error))
            
            case .success((_, let result)):
                
                guard let r = result else {
                    let error = NSError(domain: "FeedsManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "An unknown error occurred and no response was received."])
                    
                    completion?(.failure(error as Error))
                    
                    return
                }
                
                completion?(.success(r))
                
            }
            
        }
        
    }
    
}

// MARK: - Push
extension FeedsManager {
    
    public func onSetPushToken() {
        
        if subsribeAfterPushEnabled != nil {
            
            subscribe(subsribeAfterPushEnabled!) { [weak self] result in
                
                switch result {
                
                case .failure(let error):
                    print("Error subbing to feed after push was enabled: \(error)")
                    self?.subsribeAfterPushEnabled = nil
                    
                case .success:
                    NotificationCenter.default.post(name: Notification.Name.init(rawValue: "com.yeti.note.subscribedToFeed"), object: self?.subsribeAfterPushEnabled)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        
                        self?.subsribeAfterPushEnabled = nil
                        
                    }
                    
                }
                
            }
            
        }
        
        if pushToken != nil {
            addPushToken(token: pushToken!, completion: nil)
        }
        
    }
    
    public func addPushToken(token: String, completion:((Result<Bool, Error>) -> Void)?) {
        
        session.PUT(path: "/user/token", query: nil, body: ["token": token], resultType: [String: Int].self) { result in
            
            switch result {
            case .failure(let error):
                print(error)
                completion?(.failure(error))
            case .success(let (response, status)):
                print(response?.statusCode ?? 0, status ?? "No response value")
                completion?(.success(true))
            }
            
        }
        
    }
    
    public func getAllWebSub(completion:((Result<[Feed], Error>) -> Void)?) {
        
        session.GET(path: "/user/subscriptions", query: nil, resultType: [Feed].self) { result in
            
            switch result {
            case .failure(let error):
                completion?(.failure(error))
            case .success(let (_, feeds)):
                completion?(.success(feeds ?? []))
            }
            
        }
        
    }
    
    public func subscribe(_ feed: Feed, completion:((Result<Bool, Error>) -> Void)?) {
        
        session.PUT(path: "/user/subscriptions", query: ["feedID": "\(feed.feedID!)"], body: [:], resultType: [String: Bool].self) { result in
            
            switch result {
            case .failure(let error):
                completion?(.failure(error))
            case .success(let (_, result)):
                completion?(.success(result?["status"] ?? false))
            }
            
        }
        
    }
    
    public func unsubscribe(_ feed: Feed, completion:((Result<Bool, Error>) -> Void)?) {
        
        session.DELETE(path: "/user/subscriptions", query: ["feedID": "\(feed.feedID!)"], resultType: [String: Bool].self) { result in
            
            switch result {
            case .failure(let error):
                completion?(.failure(error))
            case .success(let (_, result)):
                completion?(.success(result?["status"] ?? false))
            }
            
        }
        
    }
    
}

// MARK: - Sync
extension FeedsManager {
    
    public func sync(with token:String, tokenID: String, page: UInt, completion:((Result<ChangeSet, Error>) -> Void)?) {
        
        guard let user = user else {
            completion?(.failure((NSError(domain: "Elytra", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not logged in."]) as Error)))
            return
        }
        
        let query = [
            "token": token,
            "tokenID": tokenID,
            "userID": "\(user.userID!)",
            "page": "\(page)"
        ]
        
        session.GET(path: "/2.2.1/sync", query: query) { result -> Result<ChangeSet, Error> in
            
            switch result {
            case .success(let (_, result)):
                
                guard let data = result else {
                    return Result.failure(FeedsManagerError.from(description: "Invalid or no data was received.", statusCode: 500))
                }
                
                do {
                    
                    let json = try JSON(data: data)
                    
                    guard let s = json.dictionaryObject else {
                        return .failure(FeedsManagerError.general(message: "Invalid data received."))
                    }

                    let changeSet: ChangeSet = ChangeSet.init(from: s)

                    return .success(changeSet)
                    
                }
                catch {
                    return .failure(error)
                }
                
            case .failure(let error):
                print(error)
                return Result.failure(error)
            }
            
        } completion: { result in
            
            switch result {
            case .success(let (response, changeSet)):
                
                guard let response = response else {
                    completion?(.failure(FeedsManagerError.from(description: "No response was received when trying to fetch sync data.", statusCode: 500)))
                    return
                }
                
                if response.statusCode == 304 || changeSet == nil {
                    let dummy = ChangeSet(from: [:])
                    completion?(.success(dummy))
                    return
                }
                
                completion?(.success(changeSet!))
                
            case .failure(let error):
                completion?(.failure(error))
            }
                
        }
        
    }
    
}

// MARK: - Filters
extension FeedsManager {
    
    public func getFilters(completion:((Result<[String], Error>) -> Void)?) {
        
        guard let _ = self.user else {
            completion?(.failure(FeedsManagerError.from(description: "An invalid or no session exists.", statusCode: 401)))
            return
        }
        
        session.GET(path: "/user/filters", query: nil, resultType: [String: [String]].self) { result in
            
            switch result {
            case .success(let (response, result)):
                
                guard let _ = response else {
                    completion?(.failure(FeedsManagerError.from(description: "No response was received when trying to add the filter.", statusCode: 500)))
                    return
                }
                
                guard let result = result else {
                    completion?(.failure(FeedsManagerError.from(description: "No response was received when trying to add the filter.", statusCode: 500)))
                    return
                }
                
                completion?(.success(result["filters"] ?? []))
                
            case .failure(let error):
                completion?(.failure(error))
            }
            
        }
        
    }
    
    public func addFilter(_ text: String, completion:((Result<Bool, Error>) -> Void)?) {
        
        guard text.isEmpty == false else {
            completion?(.failure(FeedsManagerError.from(description: "An invalid or no text was provided for the filter.", statusCode: 400)))
            return
        }
        
        session.PUT(path: "/user/filters", query: nil, body: ["word": text], resultType: [String: Bool].self) { result in
            
            switch result {
            case .success(let (response, result)):
                
                guard let response = response else {
                    completion?(.failure(FeedsManagerError.from(description: "No response was received when trying to add the filter.", statusCode: 500)))
                    return
                }
                
                guard response.statusCode != 304 else {
                    // already deleted.
                    completion?(.success(true))
                    return
                }
                
                guard let result = result else {
                    completion?(.failure(FeedsManagerError.from(description: "No response was received when trying to add the filter.", statusCode: 500)))
                    return
                }
                
                completion?(.success(result["status"] ?? false))
                
            case .failure(let error):
                completion?(.failure(error))
            }
            
        }
        
    }
    
    public func deleteFilter(_ text: String, completion:((Result<Bool, Error>) -> Void)?) {
        
        guard text.isEmpty == false else {
            completion?(.failure(FeedsManagerError.from(description: "An invalid or no text was provided for the filter.", statusCode: 400)))
            return
        }
        
        session.DELETE(path: "/user/filters", query: ["word": text], resultType: [String: Bool].self) { result in
            
            switch result {
            case .success(let (response, result)):
                
                guard let response = response else {
                    completion?(.failure(FeedsManagerError.from(description: "No response was received when trying to delete the filter.", statusCode: 500)))
                    return
                }
                
                guard response.statusCode != 304 else {
                    // already deleted.
                    completion?(.success(true))
                    return
                }
                
                guard let result = result else {
                    completion?(.failure(FeedsManagerError.from(description: "No response was received when trying to delete the filter.", statusCode: 500)))
                    return
                }
                
                completion?(.success(result["status"] ?? false))
                
            case .failure(let error):
                completion?(.failure(error))
            }
            
        }
        
    }
    
}

// MARK: - OPML
extension FeedsManager {
    
    public func getOPML(completion:@escaping ((_ xmlData: String?, _ error: Error?) -> Void)) {
        
        session.GET(path: "/user/opml", query: ["userID": "\(user!.userID!)"], resultType: [String: String].self) { result in
            
            switch result {
            case .failure(let error):
                completion(nil, error)
                
            case .success(let (_, responseObject)):
                if let xmlData = responseObject?["file"] {
                    completion(xmlData, nil)
                }
                else {
                    completion(nil, FeedsManagerError.from(description: "No file was received when exporting your subscriptions.", statusCode: 500))
                }
                
            }
            
        }
        
    }
    
}

// MARK: - Helpers
extension FeedsManager {
    
    public func checkYoutube(url:URL, completion:((Result<URL, Error>) -> Void)?) {
     
        guard var components = URLComponents(string: url.absoluteString) else {
            completion?(.failure(FeedsManagerError.general(message: "Please enter a valid URL.")))
            return
        }
        
        if components.scheme == nil {
            components.scheme = "https"
        }
        
        guard let _ = components.url else {
            completion?(.failure(FeedsManagerError.general(message: "Please enter a valid URL.")))
            return
        }
        
        guard components.host?.contains("youtube.com") == true else {
            completion?(.failure(FeedsManagerError.general(message: "Please enter a Youtube URL.")))
            return
        }
        
        let patternString = "\\/c(hannel)?\\/(.+)"
        guard let regexp = try? NSRegularExpression(pattern: patternString, options: []) else {
            completion?(.failure(FeedsManagerError.general(message: "An internal error occurred when fetching the Youtube URL.")))
            return
        }
        
        if components.path.contains("/user/") == true {
            
            // get it from the canonical head tag
            getYoutubeCannonicalID(originalURL: url, completion: completion)
            
        }
        else {
            
            var channelID: String? = nil
            var isChannelID: Bool = false
            
            regexp.enumerateMatches(in: components.path, options: [], range: NSMakeRange(0, components.path.count)) { (result, flags, stop) in
                
                guard let result = result else {
                    return
                }
                
                let matchingGroupRange = result.range(at: result.numberOfRanges - 1)
                
                channelID = (components.path as NSString).substring(with: matchingGroupRange)
                isChannelID = result.range(at: 1).location != NSNotFound
                
                stop.pointee = true
                
            }
            
            if channelID != nil {
                
                if isChannelID == false {
                    
                    // get it from the canonical head tag
                    getYoutubeCannonicalID(originalURL: url, completion: completion)
                    return
                    
                }
                
                let cannonicalURL = URL(string: "https://www.youtube.com/feeds/videos.xml?channel_id=\(channelID!)")!
                
                completion?(.success(cannonicalURL))
                
            }
            
        }
        
    }
    
    public func getYoutubeCannonicalID(originalURL: URL, completion:((Result<URL, Error>) -> Void)?) {
        
        let request = URLRequest(url: originalURL)
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                completion?(.failure(error))
                return
            }
            
            guard let data = data else {
                completion?(.failure(FeedsManagerError.from(description: "No response was received when trying to fetch sync data.", statusCode: 500)))
                return
            }
            
            guard let html = String(data: data, encoding: .utf8) else {
                completion?(.failure(FeedsManagerError.from(description: "No response was received when trying to fetch sync data.", statusCode: 500)))
                return
            }
            
            var cannonical: String? = nil
            
            let startString = "<link rel=\"alternate\" type=\"application/rss+xml\" title=\"RSS\" href=\""
            
            let scanner = Scanner(string: html)
            
            repeat {
                
                cannonical = nil
                
                let _ = scanner.scanUpToString(startString)
                
                let nextIndex = String.Index(utf16Offset: scanner.currentIndex.utf16Offset(in: scanner.string) + startString.count, in: scanner.string)
                
                scanner.currentIndex = nextIndex
                
                cannonical = scanner.scanUpToString("\"")
                
            } while (cannonical == originalURL.absoluteString)
            
            guard let c = cannonical,
                  let url = URL(string: c) else {
                
                DispatchQueue.main.async {
                    completion?(.failure(FeedsManagerError.from(description: "No response was received from Youtube", statusCode: 500)))
                }
                return
                
            }
            
            DispatchQueue.main.async {
                completion?(.success(url))
            }
            
        }
        
        task.resume()
        
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
