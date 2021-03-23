//
//  File.swift
//  
//
//  Created by Nikhil Nigade on 05/03/21.
//

import Foundation
import BetterCodable

@objcMembers public final class _Range: Codable {
    
    public var range: NSRange = NSRange()
    
    var location: Int {
        return range.location
    }
    
    var length: Int {
        return range.length
    }
    
    enum CodingKeys: String, CodingKey {
        case range
    }
    
    public init(range: NSRange) {
        self.range = range
    }
    
    public init(string: String) {
        self.range = NSRangeFromString(string)
    }
    
    public init(from decoder: Decoder) throws {
        
        let values = try decoder.singleValueContainer()
        
        let val = try values.decode(String.self)
        self.range = NSRangeFromString(val)
        
    }
    
}

@objcMembers public final class ContentRange: NSObject, Codable {
    
    public var element: String?
    @LossyOptional public var range: _Range!
    public var type: String?
    @LossyOptional public var url: URL?
    public var level: UInt?
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case element
        case type
        case url
        case level
        case range
    }
    
    public var nsRange: NSRange {
        get {
            if range != nil {
                return range.range
            }
            else {
                return NSRange()
            }
        }
        set {
            if self.range == nil {
                self.range = _Range(range: newValue)
            }
            else {
                range.range = newValue
            }
        }
    }
    
    public convenience init(from dict: [String: Any]) {
        
        self.init()
        
        setValuesForKeys(dict)
        
    }
    
    public override func setValue(_ value: Any?, forKey key: String) {
        
        if key == "element" {
            if let value = value as? String {
                element = value
            }
        }
        else if key == "range" {
            if let value = value as? NSRange {
                range = _Range(range: value)
            }
            else if let value = value as? String {
                range = _Range(string: value)
            }
        }
        else if key == "type" {
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
        else if key == "level" {
            if let value = value as? UInt {
                level = value
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
            print("ContentRange undefined key:\(key) with value:\(String(describing: value))")
            #endif
        }
        
    }
    
}

extension ContentRange {
    
    public override var description: String {
        let desc = super.description
        return "\(desc)\n\(dictionaryRepresentation)"
    }
    
    public var dictionaryRepresentation: [String: Any] {
        
        var dict: [String: Any] = [:]
        
        for name in ContentRange.CodingKeys.allCases {
            
            let key = name.rawValue
            
            if let value = value(for: key) {
            
                if key == "range" {
                    dict[key] = NSStringFromRange((value as! _Range).range)
                }
                else {
                    dict[key] = value
                }
                
            }
            
        }
        
        return dict
        
    }
    
}

extension ContentRange: Copyable {}
