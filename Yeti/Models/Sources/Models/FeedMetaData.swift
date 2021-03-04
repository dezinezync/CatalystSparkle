//
//  FeedMetaData.swift
//  
//
//  Created by Nikhil Nigade on 04/03/21.
//

import Foundation

class FeedMetaData: NSObject, Codable {
    
    var icons = [String: URL]()
    var icon: URL?
    var keywords = [String]()
    var title: String?
    var url: URL?
    var summary: String?
    var opengraph: OpenGraph?
    
    convenience init(from dict: [String: Any]) {
        
        self.init()
        
        setValuesForKeys(dict)
        
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        
        if key == "icon",
           let value = value as? String {
            
            if let url = URL(string: value) {
                icon = url
            }
            
        }
        else if key == "keywords",
                let value = value as? [String] {
            
            keywords = value
            
        }
        else if key == "title",
                let value = value as? String {
            
            title = value
            
        }
        else if key == "url",
                let value = value as? String {
            
            if let url = URL(string: value) {
                self.url = url
            }
            
        }
        else if key == "summary",
                let value = value as? String {
            
            summary = value
            
        }
        else if key == "opengraph",
                let value = value as? [String: Any] {
            
            let og = OpenGraph(from: value)
            opengraph = og
            
        }
        else {
            super.setValue(value, forKey: key)
        }
        
    }
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
        if key == "apple-touch-icon",
           let value = value as? [String: Any] {
            
            value.forEach { (arg0) in
                
                let (k, v) = arg0
                
                guard let vi = v as? String else {
                    return
                }
                
                let url = URL(string: vi)
                
                self.icons[k] = url
                
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
    
    var dictionaryRepresentation: [String: Any] {
        
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

extension FeedMetaData: Copyable { }
