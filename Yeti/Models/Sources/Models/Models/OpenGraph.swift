//
//  OpenGraph.swift
//  
//
//  Created by Nikhil Nigade on 04/03/21.
//

import Foundation

public final class OpenGraph: NSObject, Codable {
    
    public var summary: String?
    public var image: URL?
    public var locale: String?
    public var title: String?
    public var type: String?
    public var url: URL?
    
    public convenience init(from dict: [String: Any]) {
        
        self.init()
        
        setValuesForKeys(dict)
        
    }
    
    public override func setValue(_ value: Any?, forKey key: String) {
        
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
    
    public override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
        if key == "foo" {}
        else {
            #if DEBUG
            print("OpenGraph undefined key:\(key) with value:\(String(describing: value))")
            #endif
        }
        
    }
    
}

extension OpenGraph {
    
    public override var description: String {
        let desc = super.description
        return "\(desc)\n\(dictionaryRepresentation)"
    }
    
    public var dictionaryRepresentation: [String: Any] {
        
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

extension OpenGraph {
    
    static func == (lhs: OpenGraph, rhs: OpenGraph) -> Bool {
        
        return lhs.type == rhs.type
            && lhs.url == rhs.url
            && lhs.locale == rhs.locale
            && lhs.title == rhs.title
            && lhs.image == rhs.image
            && lhs.summary == rhs.summary
        
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        
        guard let object = object as? OpenGraph else { return false }
        
        return object == self
        
    }
    
}

extension OpenGraph: Copyable { }
