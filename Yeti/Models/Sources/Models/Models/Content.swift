//
//  Content.swift
//  
//
//  Created by Nikhil Nigade on 05/03/21.
//

import Foundation
import CoreGraphics
import BetterCodable

public struct ContentSize: Codable {
    
    var size: CGSize = CGSize()
    
    var width: CGFloat {
        return size.width
    }
    
    var height: CGFloat {
        return size.height
    }
    
    enum CodingKeys: String, CodingKey {
        case size
    }
    
    public init(size: CGSize) {
        self.size = size
    }
    
    public init(size: String) {
        self.size = setSize(size: size)
    }
    
    public init(from decoder: Decoder) throws {
        
        let values = try decoder.singleValueContainer()
        
        let val = try values.decode(String.self)
        self.size = setSize(size: val)
        
    }
    
    private mutating func setSize(size: String) -> CGSize {
        let comps = size.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.map { ($0 as NSString).doubleValue }
        
        if comps.count == 2 {
            
            return CGSize(width: comps.first!, height: comps.last!)
            
        }
        
        return CGSize()
        
    }
    
}

public final class Content: NSObject, Codable {
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case content
        case ranges
        case type = "node"
        case url
        case alt
        case identifier
        case level
        case items
        case attributes
        case videoID
        case srcSet
        case images
        case size
    }
    
    public var content: String?
    public var ranges: [ContentRange]?
    @LossyOptional public var type: String!
    @LossyOptional public var url: URL?
    public var alt: String?
    public var identifier: String?
    public var level: UInt?
    public var items: [Content]?
    public var attributes: [String: String]?
    public var videoID: String?
    
    // Determines if this Content block was programatically created from the enclosures.
    public var fromEnclosure: Bool = false
    
    // for images
    public var size: ContentSize?
    public var srcSet: [String: String]?
    
    public var images: [Content]?
    
    public weak var downloadTask: URLSessionTask?
    
    public convenience init(from dict: [String: Any]) {
        
        self.init()
        
        setValuesForKeys(dict)
        
    }
    
    public convenience init(from array: [[String: Any]]) {
        
        self.init()
        
        setValue(array, forKey: "items")
        
    }
    
    public override func setValue(_ value: Any?, forKey key: String) {
        
        if key == "content" {
            if let value = value as? String {
                content = value
            }
            else {
                self.setValue(value, forKey: "items")
            }
        }
        else if key == "ranges" {
            
            if let value = value as? [String: Any] {
                
                let object = ContentRange(from: value)
                ranges = [object]
                
            }
            else if let value = value as? [[String: Any]] {
                
                let objects = value.map { ContentRange(from: $0) }
                ranges = objects
                
            }
            else if let value = value as? [ContentRange] {
                ranges = value
            }
            else if let value = value as? ContentRange {
                ranges = [value]
            }
            
        }
        else if key == "type" || key == "node" {
            if let value = value as? String {
                type = value
            }
        }
        else if key == "url" {
            if let value = value as? URL {
                url = value
            }
            else if let value = value as? String {
                url = URL(string: value)
            }
        }
        else if key == "alt" {
            if let value = value as? String {
                alt = value
            }
        }
        else if key == "identifier" || key == "id" {
            if let value = value as? String {
                identifier = value
            }
        }
        else if key == "level" {
            if let value = value as? UInt {
                level = value
            }
        }
        else if key == "items" {
            if let value = value as? [[String: Any]] {
                
                let objects = value.map { Content(from: $0) }
                items = objects
                
            }
            else if let value = value as? Content {
                items = [value]
            }
            else if let value = value as? [Content] {
                items = value
            }
            else if let value = value as? [String: Any] {
                
                let object = Content(from: value)
                items = [object]
                
            }
        }
        else if key == "attributes" || key == "attr" {
            
            if let value = value as? [String: String] {
                attributes = value
            }
            
        }
        else if key == "videoID" {
            if let value = value as? String {
                videoID = value
            }
        }
        else if key == "size" {
            if let value = value as? CGSize {
                size = ContentSize(size: value)
            }
            else if let value = value as? String {
                size = ContentSize(size: value)
            }
        }
        else if key == "srcSet" || key == "srcset" {
            if let value = value as? [String: String] {
                srcSet = value
            }
        }
        else if key == "images" {
            if let value = value as? [[String: Any]] {
                
                let objects = value.map { Content(from: $0) }
                images = objects
                
            }
            else if let value = value as? Content {
                images = [value]
            }
            else if let value = value as? [Content] {
                images = value
            }
            else if let value = value as? [String: Any] {
                
                let object = Content(from: value)
                images = [object]
                
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
            print("Content undefined key:\(key) with value:\(String(describing: value))")
            #endif
        }
        
    }
    
}

extension Content {
    
    public override var description: String {
        let desc = super.description
        return "\(desc)\n\(dictionaryRepresentation)"
    }
    
    public var dictionaryRepresentation: [String: Any] {
        
        var dict = [String: Any]()
        
        if let content = content {
            dict["content"] = content
        }
        
        dict["ranges"] = (ranges ?? []).map { $0.dictionaryRepresentation }
        dict["type"] = type
        
        if let url = url {
            dict["url"] = url.absoluteString
        }
        
        if let alt = alt {
            dict["alt"] = alt
        }
        
        if let identifier = identifier {
            dict["identifier"] = identifier
        }
        
        if let level = level {
            dict["level"] = level
        }
        
        if let items = items {
            dict["items"] = items.map { $0.dictionaryRepresentation }
        }
        
        if let attributes = attributes {
            dict["attributes"] = attributes
        }
        
        if let videoID = videoID {
            dict["videoID"] = videoID
        }
        
        if let size = size {
            dict["size"] = "\(size.width),\(size.height)"
        }
        
        if let srcSet = srcSet {
            dict["srcSet"] = srcSet
        }
        
        if let images = images {
            dict["images"] = images.map { $0.dictionaryRepresentation }
        }
        
        return dict
        
    }
    
}

extension Content: Copyable {}
