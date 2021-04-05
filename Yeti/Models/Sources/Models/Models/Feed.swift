//
//  Feed.swift
//  
//
//  Created by Nikhil Nigade on 02/03/21.
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

public let kFeedSafariReaderMode = "com.elytra.feed.safariReaderMode"
public let kFeedLocalNotifications = "com.elytra.feed.localNotifications"

private let imageExtensions = ["png", "jpg", "jpeg", "svg", "bmp", "ico", "webp", "gif"]

@objcMembers public class Feed: NSObject, Codable, ObservableObject {

    public var feedID: UInt!
    public var summary: String!
    public var title: String!
    public var url: URL!
    public var favicon: URL?
    public var extra: FeedMetaData?
    public var rpcCount: UInt! = 0
    public var lastRPC: Date?
    public var hubSubscribed: Bool! = false
    public var subscribed: Bool! = false
    public var folderID: UInt? = 0
    public var localName: String?
    public var podcast: Bool! = false
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case feedID = "id"
        case summary
        case title
        case url
        case favicon
        case extra
        case rpcCount
        case lastRPC
        case hubSubscribed
        case subscribed
        case folderID
        case localName
        case podcast
    }
    
    @Published public var unread: UInt = 0
    
    weak var folder: Folder?
    
    #if os(macOS)
    @Published public var faviconImage: NSImage?
    #else
    @Published public var faviconImage: UIImage?
    #endif
    
    public var canShowExtraLevel: Bool {
        
        guard let extra = extra else {
            return false
        }
        
        return extra.url != nil
        
    }
    
    public convenience init(from dict: [String: Any]) {
        
        self.init()
        
        setValuesForKeys(dict)
        
    }
    
    fileprivate(set) var _faviconURI: URL?
    public var faviconURI: URL? {
        
        guard _faviconURI == nil else {
            return _faviconURI!
        }
        
        var url: URL? = nil
        
        // check if this is a youtube channel
        let isYoutubeChannel = self.url.absoluteString.contains("feeds/videos.xml?channel_id=")
        
        if isYoutubeChannel == true,
           let ogImage = extra?.opengraph?.image {
            
            url = ogImage
            
        }
        
        if url == nil,
           let favicon = favicon,
           favicon.absoluteString.isEmpty == false {
            
            url = favicon
            
        }
        
        if url == nil, let extra = extra {
            
            if extra.icons?.count ?? 0 > 0 {
                
                if let base = extra.icons?["base"] {
                    
                    url = base
                    
                }
                
                // sort keys by size
                let sortedKeys = extra.icons?.keys.map { ($0 as NSString).integerValue }.sorted() ?? []
                
                let key = "\(sortedKeys.last!)"
                
                if let icon = extra.icons?[key] {
                    
                    url = icon
                    
                }
                
            }
            else if let og = extra.opengraph,
                    let image = og.image {
                
                url = image
                
            }
            
        }
        
        if let uri = url {
            
            // opengraph can only contain images (samwize)
            let pathExtension = uri.pathExtension
            
            // the path extension can be blank for gravatar URLs
            if pathExtension.isEmpty == false,
               imageExtensions.contains(pathExtension) == false {
                
                url = nil
                
            }
            
        }
        
        if url == nil,
           let icon = extra?.icon,
           icon.absoluteString.isEmpty == false {
            
            url = icon
            
        }
        
        if url == nil,
           let fav = favicon,
           fav.absoluteString.isEmpty == false {
            
            url = fav
            
        }
        
        guard var uri = url else {
            return nil
        }
        
        // ensure this is a not a relative URL
        guard var components = URLComponents(string: uri.absoluteString) else {
            
            _faviconURI = url
            return _faviconURI
            
        }
        
        if components.host == nil {
            
            // relative string
            guard var comps = URLComponents(string: extra?.url?.absoluteString ?? "") else {
                
                return nil
                
            }
            
            comps.path = uri.absoluteString
            
            uri = comps.url ?? uri
            
            components = URLComponents(string: uri.absoluteString)!
            
        }
        
        if components.scheme == nil {
            
            components.scheme = "https"
            
            uri = components.url ?? uri
            
        }
        
        if uri.pathExtension.contains("ico") {
            
            guard let googleURL = URL(string: "https://www.google.com/s2/favicons?domain=\(components.host ?? "")") else {
                
                return nil
                
            }
            
            uri = googleURL
            
        }
        
        _faviconURI = uri
        return _faviconURI
        
        
    }
    
    public var displayTitle: String {
        return localName ?? title
    }
    
    public override func setValue(_ value: Any?, forKey key: String) {
        
        if key == "extra", let value = value as? [String: Any] {
            
            let extra = FeedMetaData(from: value)
            
            self.extra = extra
            
        }
        else if key == "title",
                let value = value as? String {
            title = value
        }
        else if key == "rpcCount" {
            
            if let value = value as? UInt {
                rpcCount = value
            }
            
        }
        else if key == "url",
                let value = value as? String {
            
            if let url = URL(string: value) {
                self.url = url
            }
            
        }
        else if key == "favicon" {
            
            if let value = value as? String {
                if let url = URL(string: value) {
                    favicon = url
                }
            }
            else if let value = value as? URL {
                favicon = value
            }
            
        }
        else if key == "lastRPC" {
            
            if let value = value as? String,
               let date = Subscription.dateFormatter.date(from: value) {
                lastRPC = date
            }
            
        }
        else if key == "hubSubscribed",
                let value = value as? Bool {
            
            hubSubscribed = value
            
        }
        else if key == "podcast",
                let value = value as? Bool {
            
            podcast = value
            
        }
        else {
            
            super.setValue(value, forKey: key)
            
        }
        
    }
    
    public override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
        if key == "feed", let value = value as? [String: Any] {
            
            return setValuesForKeys(value)
            
        }
        else if key == "summary",
                let value = value as? String {
            
            summary = value
            
        }
        else if key == "id", let value = value as? UInt {
            
            feedID = value
            
        }
        else {
            #if DEBUG
            print("Feed undefined key:\(key) with value:\(String(describing: value))")
            #endif
        }
        
    }
    
}

extension Feed {
    
    public override var description: String {
        let desc = super.description
        return "\(desc)\n\(dictionaryRepresentation)"
    }
    
    var dictionaryRepresentation: [String: Any] {
        
        var dict: [String: Any] = [:]
        
        for name in Feed.CodingKeys.allCases {
            
            let key = name.rawValue
            
            if var val = value(for: key) {
                
                if key == "extra" {
                    val = (val as! FeedMetaData).dictionaryRepresentation
                }
                
                dict[key] = val
                
            }
            
        }
        
        return dict
        
    }
    
}

extension Feed {
    
    static func == (lhs: Feed, rhs: Feed) -> Bool {
        
        let equal = lhs.url == rhs.url
            && lhs.feedID == rhs.feedID
            && lhs.displayTitle == rhs.displayTitle
        
        return equal
        
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        
        guard let object = object as? Feed else { return false }
        
        return object == self
        
    }
    
}

extension Feed: Copyable {}
