//
//  FeedsLib.swift
//  Elytra
//
//  Created by Nikhil Nigade on 16/02/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import WebKit

@objc public class FeedsLib: NSObject {
    
    public static let shared = FeedsLib()
    
    internal let uaString: String? = {
        
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        
        var value: String? = nil
        
        let semaphore = DispatchSemaphore(value: 1)
        
        webView.evaluateJavaScript("navigator.userAgent") { result, _ in
            value = result as? String
            semaphore.signal()
        }
        
        semaphore.wait()
        
        return value
        
    }()
    
    internal lazy var session: URLSession = {
       
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": self.uaString ?? "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1"]
        
        let s = URLSession(configuration: config)
        
        return s
        
    }()
    
    internal let baseURL = URL(string:"https://feedly.com")
    
    public func getRecommendations(topic: String, locale: String?, completion: ((_ error: Error?, _ data: RecommendationsResponse?) -> Void)?) {
        
        let localeString = locale ?? "en"
        
        let path = "/v3/recommendations/topics/\(topic)?context=discover&locale=\(localeString)"
        
        guard let url = URL(string: path, relativeTo: baseURL) else {
            return
        }
        
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        
        session.dataTask(with: request) { [weak self] data, response, error in
            
            if (error != nil) {
                
                DispatchQueue.main.async {
                    completion?(error, nil)
                }
                return
                
            }
            
            if let data = data {
                do {
                    
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .custom({ (aDecoder) -> Date in
                        
                        let container = try aDecoder.singleValueContainer()
                        let dateValueMilliseconds = try container.decode(Double.self)
                        
                        let dateVal = dateValueMilliseconds/1000
                        let date = Date(timeIntervalSince1970:dateVal)
                        
                        return date
                        
                    })
                    
                    let result = try decoder.decode(RecommendationsResponse.self, from: data)
                    
                    DispatchQueue.main.async {
                        completion?(nil, result)
                    }
                    
                    return
                    
                }
                catch {
                    print(error)
                }
            }
            
            guard let sself = self else {
                return
            }
            
            sself.processResponse(data: data) { (error: Error?, retval: [String: Any]?) in
                
                if let error = error {
                    DispatchQueue.main.async {
                        completion?(error, nil)
                    }
                    return
                }
                
                if let result = try? RecommendationsResponse(from: retval as Any) {
                    
                    DispatchQueue.main.async {
                        completion?(nil, result)
                    }
                    return
                }
                
                
                return
                
            }
            
        }.resume()
        
    }
    
    public func getFeedInfo(url: URL, completion: ((_ error: Error?, _ data: FeedInfoResponse?) -> Void)?) {
        
        let query = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url.absoluteString
        
        let path = "/v3/search/feeds?query=\(query)"
        
        guard let url = URL(string: path, relativeTo: baseURL) else {
            return
        }
        
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        
        session.dataTask(with: request) { [weak self] data, response, error in
            
            if (error != nil) {
                
                DispatchQueue.main.async {
                    completion?(error, nil)
                }
                return
                
            }
            
            if let data = data {
                do {
                    
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .custom({ (aDecoder) -> Date in
                        
                        let container = try aDecoder.singleValueContainer()
                        let dateValueMilliseconds = try container.decode(Double.self)
                        
                        let dateVal = dateValueMilliseconds/1000
                        let date = Date(timeIntervalSince1970:dateVal)
                        
                        return date
                        
                    })
                    
                    let result = try decoder.decode(FeedInfoResponse.self, from: data)
                    
                    completion?(nil, result)
                    return
                    
                }
                catch {
                    print(error)
                }
            }
            
            guard let sself = self else {
                return
            }
            
            sself.processResponse(data: data) { (error: Error?, retval: [String: Any]?) in
                
                if let error = error {
                    DispatchQueue.main.async {
                        completion?(error, nil)
                    }
                    return
                }
                
                if let result = try? FeedInfoResponse(from: retval as Any) {
                    
                    DispatchQueue.main.async {
                        completion?(nil, result)
                    }
                    return
                }
                
                
                return
                
            }
            
        }.resume()
        
    }
    
    internal func processResponse(data: Data?, completion: ((_ error: Error?, _ data: [String: Any]?) -> Void)?) {
        
        guard let data = data else {
            
            let err = NSError(domain: "FeedsLib", code: 501, userInfo: [NSLocalizedDescriptionKey: "No data in response"])
            
            DispatchQueue.main.async {
                completion?(err as Error, nil)
            }
            
            return
        }
        
        do {
            
            if let decodedResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                
                if let errorMessage = decodedResponse["errorMessage"] {
                    
                    let err = NSError(domain: "Feedly", code: (decodedResponse["errorCode"] as? NSNumber)?.intValue ?? 500, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    
                    DispatchQueue.main.async {
                        completion?(err as Error, nil)
                    }
                    
                    return
                    
                }
                else {
                    
                    DispatchQueue.main.async {
                        completion?(nil, decodedResponse)
                    }
                    
                }
                
            }
            else {
                let err = NSError(domain: "FeedsLib", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid Response Type"])
                
                DispatchQueue.main.async {
                    completion?(err as Error, nil)
                }
            }
            
        }
        catch {
            completion?(error, nil)
        }
        
    }
    
}

// MARK: - Private

extension Decodable {
  init(from: Any) throws {
    let data = try JSONSerialization.data(withJSONObject: from, options: .prettyPrinted)
    let decoder = JSONDecoder()
    self = try decoder.decode(Self.self, from: data)
  }
}
