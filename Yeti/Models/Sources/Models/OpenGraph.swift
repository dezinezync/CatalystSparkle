//
//  OpenGraph.swift
//  
//
//  Created by Nikhil Nigade on 04/03/21.
//

import Foundation

class OpenGraph: NSObject, Codable {
    
    var summary: String?
    var image: URL?
    var locale: String?
    var title: String?
    var type: String?
    var url: URL?
    
    convenience init(from dict: [String: Any]) {
        
        self.init()
        
        setValuesForKeys(dict)
        
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        
        if key == "image",
           let value = value as? String {
            
            if let url = URL(string: value) {
                image = url
            }
            
        }
        else if key == "type",
                let value = value as? String {
            
            type = value
            
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
        else if key == "description",
                let value = value as? String {
            
            summary = value
            
        }
        else if key == "locale",
                let value = value as? String {
            
            locale = value
            
        }
        else {
            super.setValue(value, forKey: key)
        }
        
    }
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
        if key == "foo" {}
        else {
            #if DEBUG
            print("FeedMetaData undefined key:\(key) with value:\(String(describing: value))")
            #endif
        }
        
    }
    
}

extension OpenGraph {
    
    var dictionaryRepresentation: [String: Any] {
        
        var dict = [String: Any]()
        
        if let summary = summary {
            dict["summary"] = summary
        }
        
        if let image = image {
            dict["image"] = image.absoluteString
        }
        
        if let url = url {
            dict["url"] = url.absoluteString
        }
        
        if let locale = locale {
            dict["locale"] = locale
        }
        
        if let title = title {
            dict["title"] = title
        }
        
        if let type = type {
            dict["type"] = type
        }
        
        return dict
        
    }
    
}

extension OpenGraph: Copyable { }
