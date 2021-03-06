//
//  File.swift
//  
//
//  Created by Nikhil Nigade on 05/03/21.
//

import Foundation

final class ContentRange: NSObject, Codable {
    
    var element: String?
    var range: NSRange!
    var type: String?
    var url: URL?
    var level: UInt?
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case element
        case range
        case type
        case url
        case level
    }
    
    convenience init(from dict: [String: Any]) {
        
        self.init()
        
        setValuesForKeys(dict)
        
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        
        if key == "element" {
            if let value = value as? String {
                element = value
            }
        }
        else if key == "range" {
            if let value = value as? NSRange {
                range = value
            }
            else if let value = value as? String {
                range = NSRangeFromString(value)
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
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
        if key == "foo" {}
        else {
            #if DEBUG
            print("ContentRange undefined key:\(key) with value:\(String(describing: value))")
            #endif
        }
        
    }
    
}

extension ContentRange {
    
    override var description: String {
        let desc = super.description
        return "\(desc)\n\(dictionaryRepresentation)"
    }
    
    var dictionaryRepresentation: [String: Any] {
        
        var dict = [String: Any]()
        
        for name in ContentRange.CodingKeys.allCases {
            
            let key = name.rawValue
            
            if let value = value(for: key) {
            
                if key == "range" {
                    dict[key] = NSStringFromRange(value as! NSRange)
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
