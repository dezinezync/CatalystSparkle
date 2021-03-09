//
//  FeedMetaData.swift
//  
//
//  Created by Nikhil Nigade on 04/03/21.
//

import Foundation

public final class FeedMetaData: NSObject, Codable {
    
    public var icons: [String: URL]?
    public var icon: URL?
    public var keywords: [String]?
    public var title: String?
    public var url: URL?
    public var summary: String?
    public var opengraph: OpenGraph?
    
    public convenience init(from dict: [String: Any]) {
        
        self.init()
        
        setValuesForKeys(dict)
        
    }
    
    public override func setValue(_ value: Any?, forKey key: String) {
        
        if key == "icon" {
            
            if let value = value as? String {
                icon = URL(string: value)
            }
            
            else if let url = value as? URL {
                icon = url
            }
            
        }
        else if key == "keywords" {
            
            if let value = value as? [String] {
            
                keywords = value
                
            }
            else if let value = value as? String {
                
                if value.contains(",") == true {
                    
                    let keywords = value
                        .components(separatedBy: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    
                    self.keywords = keywords
                    
                }
                else {
                    keywords = [value]
                }
                
            }
            
        }
        else if key == "title" {
            
            if let value = value as? String {
                title = value
            }
            
        }
        else if key == "url" {
            
            if let value = value as? String {
                self.url = URL(string: value)
            }
            
            else if let url = value as? URL {
                self.url = url
            }
            
        }
        else if key == "summary" {
            
            if let value = value as? String {
                summary = value
            }
            
        }
        else if key == "opengraph" {
            
            if let value = value as? [String: Any] {
            
                let og = OpenGraph(from: value)
                opengraph = og
                
            }
            
        }
        else {
            super.setValue(value, forKey: key)
        }
        
    }
    
    public override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
        if key == "apple-touch-icon",
           let value = value as? [String: Any] {
            
            if icons == nil {
                icons = [String: URL]()
            }
            
            value.forEach { (arg0) in
                
                let (k, v) = arg0
                
                guard let vi = v as? String else {
                    return
                }
                
                let url = URL(string: vi)
                
                self.icons?[k] = url
                
            }
            
        }
        else {
            #if DEBUG
            print("FeedMetaData undefined key:\(key) with value:\(String(describing: value))")
            #endif
        }
        
    }
    
}

extension FeedMetaData {
    
    public override var description: String {
        let desc = super.description
        return "\(desc)\n\(dictionaryRepresentation)"
    }
    
    public var dictionaryRepresentation: [String: Any] {
        
        var dict = [String: Any]()
        
        dict["icons"] = icons
        
        dict["keywords"] = keywords
        
        if let icon = icon {
            
            dict["icon"] = icon.absoluteString
            
        }
        
        if let title = title {
            
            dict["title"] = title
            
        }
        
        if let url = url {
            
            dict["url"] = url.absoluteString
            
        }
        
        if let summary = summary {
            
            dict["summary"] = summary
            
        }
        
        if let og = opengraph {
            
            dict["opengraph"] = og.dictionaryRepresentation
            
        }
        
        return dict
        
    }
    
}

extension FeedMetaData {
    
    static func == (lhs: FeedMetaData, rhs: FeedMetaData) -> Bool {
        
        return lhs.opengraph == rhs.opengraph
            && lhs.icons == rhs.icons
            && lhs.icon == rhs.icon
            && lhs.keywords == rhs.keywords
            && lhs.title == rhs.title
            && lhs.url == rhs.url
            && lhs.summary == rhs.summary
        
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        
        guard let object = object as? FeedMetaData else { return false }
        
        return object == self
        
    }
    
}

extension FeedMetaData: Copyable { }
