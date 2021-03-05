//
//  Enclosure.swift
//  
//
//  Created by Nikhil Nigade on 05/03/21.
//

import Foundation

class Enclosure: NSObject, Codable {
    
    var length: Double?
    var type: String!
    var url: URL!
    
    convenience init(from dict: [String: Any]) {
        
        self.init()
        
        setValuesForKeys(dict)
        
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        
        if key == "length" {
            
            if let value = value as? Double {
                length = value
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
        else {
            super.setValue(value, forKey: key)
        }
        
    }
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
        if key == "foo" {}
        else {
            #if DEBUG
            print("Enclosure undefined key:\(key) with value:\(String(describing: value))")
            #endif
        }
        
    }
    
}

extension Enclosure {
    
    var dictionaryRepresentation: [String: Any] {
        
        var dict = [String: Any]()
        
        if let length = length {
            dict["length"] = length
        }
        
        dict["type"] = type
        dict["url"] = url.absoluteString
        
        return dict
        
    }
    
}

extension Enclosure: Copyable {}
