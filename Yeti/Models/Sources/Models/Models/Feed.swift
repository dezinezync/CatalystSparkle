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

class Feed: NSObject, Codable, ObservableObject {
    
    var feedID: UInt!
    var summary: String!
    var title: String!
    var url: URL!
    var favicon: URL?
    var extra: FeedMetaData?
    var rpcCount: UInt! = 0
    var lastRPC: Date?
    var hubSubscribed: Bool! = false
    var subscribed: Bool! = false
    var folderID: UInt? = 0
    var localName: String?
    var podcast: Bool! = false
    
    private enum CodingKeys: String, CodingKey, CaseIterable {
        case feedID
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
    
    @Published var unread: UInt! = 0
    
    weak var folder: Folder?
    #if os(macOS)
    var faviconImage: NSImage?
    #else
    var faviconImage: UIImage?
    #endif
    
    var canShowExtraLevel: Bool {
        
        guard let extra = extra else {
            return false
        }
        
        return extra.url != nil
        
    }
    
    convenience init(from dict: [String: Any]) {
        
        self.init()
        
        setValuesForKeys(dict)
        
    }
    
    internal var _faviconURI: URL?
    var faviconURI: URL? {
        
        guard _faviconURI == nil else {
            return _faviconURI!
        }
        
        var url: URL? = nil
        
        // check if this is a youtube channel
        let isYoutubeChannel = self.url.absoluteString.contains("feeds/videos.xml?channel_id=")
        
        if isYoutubeChannel == true,
           let ogImage = value(for: "extra.opengraph.image") as? URL {
            
            url = ogImage
            
        }
        
        if url != nil,
           let favicon = favicon,
           favicon.absoluteString.isEmpty == false {
            
            url = favicon
            
        }
        
        if let extra = extra {
            
            if extra.icons.count > 0 {
                
                if let base = extra.icons["base"] {
                    
                    url = base
                    
                }
                
                // sort keys by size
                let sortedKeys = extra.icons.keys.sorted()
                
                if let icon = extra.icons[sortedKeys.last!] {
                    
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
            var pathExtension = uri.pathExtension
            
            if pathExtension.contains("?") {
                
                let range = (pathExtension as NSString).range(of: "?")
                
                pathExtension = (pathExtension as NSString).substring(to: range.location) as String
                
                // the path extension can be blank for gravatar URLs
                if pathExtension.isEmpty == false,
                   imageExtensions.contains(pathExtension) == false {
                    
                    url = nil
                    
                }
                
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
    
    var displayTitle: String {
        return localName ?? title
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        
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
        else if key == "favicon",
                let value = value as? String {
            
            if let url = URL(string: value) {
                favicon = url
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
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
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
    
    override var description: String {
        let desc = super.description
        return "\(desc)\n\(dictionaryRepresentation)"
    }
    
    var dictionaryRepresentation: [String: Any] {
        
        var dict = [String: Any]()
        
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
    
    static func == (lhs: Feed, rhs: Feed) -> Bool {
        
        switch (lhs, rhs) {
        case (lhs, rhs): do {
            return lhs.url == rhs.url && lhs.feedID == rhs.feedID
        }
        default:
            return false
        }
        
    }
    
}

extension Feed: Copyable {}
