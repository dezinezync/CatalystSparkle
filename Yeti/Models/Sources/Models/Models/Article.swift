//
//  File.swift
//  
//
//  Created by Nikhil Nigade on 05/03/21.
//

import Foundation

public final class Article: NSObject, Codable, ObservableObject {
    
    public var identifier: UInt!
    public var title: String?
    public var url: URL!
    public var author: String?
    public var content = [Content]()
    public var coverImage: URL!
    public var guid: String!
    public var timestamp: Date!
    public var enclosures = [Enclosure]()
    public var feedID: UInt!
    public var summary: String?
    
    @Published public var bookmarked: Bool! = false
    @Published public var read: Bool! = false
    @Published public var fulltext: Bool! = false
    
    public convenience init(from dict: [String: Any]) {
        
        self.init()
        
        setValuesForKeys(dict)
        
    }
    
    public override func setValue(_ value: Any?, forKey key: String) {
        
        if key == "content" {
            
            if let value = value as? [String: Any] {
                
                let object = Content(from: value)
                content = [object]
                
            }
            else if let value = value as? [[String: Any]] {
                
                let objects = value.map { Content(from: $0) }
                content = objects
                
            }
            else if let value = value as? [Content] {
                content = value
            }
            else if let value = value as? Content {
                content = [value]
            }
            
        }
        else if key == "id" || key == "identifer" {
            
            if let value = value as? UInt {
                identifier = value
            }
            
        }
        else if key == "title" || key == "articleTitle" {
            
            if let value = value as? String {
                title = value
            }
            
        }
        else if key == "fulltext" || key == "mercury" {
            
            if let value = value as? Bool {
                fulltext = value
            }
            
        }
        else if key == "url" || key == "articleURL" {
            
            if let value = value as? URL {
                url = value
            }
            else if let value = value as? String {
                url = URL(string: value)
            }
            
        }
        else if key == "coverimage" || key == "coverImage" {
            
            if let value = value as? URL {
                coverImage = value
            }
            else if let value = value as? String {
                coverImage = URL(string: value)
            }
            
        }
        else if key == " timestamp" || key == "created" {
            
            if let value = value as? Date {
                timestamp = value
            }
            else if let value = value as? String,
                    let dateVal = Subscription.dateFormatter.date(from: value) {
                timestamp = dateVal
            }
            
        }
        else if key == "guid" {
            if let value = value as? String {
                guid = value
            }
        }
        else if key == "author" {
            if let value = value as? String {
                author = value.stripHTML()
            }
        }
        else if key == "enclosures" {
            
            if let value = value as? [String: Any] {
                
                let object = Enclosure(from: value)
                enclosures = [object]
                
            }
            else if let value = value as? [[String: Any]] {
                
                let objects = value.map { Enclosure(from: $0) }
                enclosures = objects
                
            }
            else if let value = value as? [Enclosure] {
                enclosures = value
            }
            else if let value = value as? Enclosure {
                enclosures = [value]
            }
            
        }
        else if key == "summary" {
            
            if let value = value as? String {
                
                summary = value.stripHTML()
                
            }
            
        }
        else if key == "bookmarked" {
            
            if let value = value as? Bool {
                bookmarked = value
            }
            
        }
        else if key == "read" {
            
            if let value = value as? Bool {
                read = value
            }
            
        }
        else if key == "fulltext" || key == "mercury" {
            
            print("value is \(String(describing:value))")
            
            if let value = value as? Bool {
                fulltext = value
            }
            
        }
        else {
            super.setValue(value, forKey: key)
        }
        
    }
    
    public override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
        if key == "foo" {}
        else {
            #if DEBUG
            print("Article undefined key:\(key) with value:\(String(describing: value))")
            #endif
        }
        
    }
    
}

extension Article {
    
    public override var description: String {
        let desc = super.description
        return "\(desc)\n\(dictionaryRepresentation)"
    }
    
    private func textFromContent(content: Content) -> String {
        
        var string = ""
        
        if let text = content.content {
            string = text
        }
        else if let items = content.items, items.count > 0 {
            
            string = items.map { textFromContent(content: $0) }.joined(separator: " ")
            
        }
        
        return string
        
    }

    public var textFromContent: String? {
        
        var string = ""
        
        guard content.count > 0 else {
            return string
        }
        
        for item in content {
            
            let substr = textFromContent(content: item)
            
            string += " \(substr)"
            
        }
        
        return string.trimmingCharacters(in: .whitespacesAndNewlines)
        
    }
    
    public var dictionaryRepresentation: [String: Any] {
        
        var dict = [String: Any]()
        
        dict["identifier"] = identifier
        dict["title"] = title
        dict["url"] = url.absoluteString
        
        if let author = author {
            dict["author"] = author
        }
        
        dict["bookmarked"] = bookmarked
        dict["read"] = read
        dict["fulltext"] = fulltext
        
        dict["content"] = content.map { $0.dictionaryRepresentation }
        
        if let coverImage = coverImage {
            dict["coverImage"] = coverImage.absoluteString
        }
        
        dict["guid"] = guid
        
        dict["timestamp"] = Subscription.dateFormatter.string(from: timestamp)
        
        dict["enclosures"] = enclosures.map { $0.dictionaryRepresentation }
        
        dict["feedID"] = feedID
        
        if let summary = summary {
            dict["summary"] = summary
        }
        
        return dict
        
    }
    
}

extension Article: Copyable { }
