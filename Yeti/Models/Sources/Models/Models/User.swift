//
//  User.swift
//  
//
//  Created by Nikhil Nigade on 02/03/21.
//

import Foundation

public final class User: NSObject, Codable {
    
    public var uuid: String!
    public var userID: UInt!
    public var filters = Set<String>()
    public var subscription: Subscription!
    
    public convenience init(from dict: [String: Any]) {
        
        self.init()
        
        setValuesForKeys(dict)
        
    }
    
    public override func setValue(_ value: Any?, forKey key: String) {
        
        if key == "uuid", let val = value as? String {
            uuid = val
        }
        else if key == "filters" {
            
            if let items = value as? Set<String> {
                
                items.forEach({
                    filters.insert($0)
                })
                
            }
            
            else if let items = value as? [String] {
                
                items.forEach({
                    filters.insert($0)
                })
                
            }
            
        }
        else if key == "subscription" {
            
            if let value = value as? Subscription {
                subscription = value
            }
            else if let value = value as? [String: Any] {
                subscription = Subscription(from: value)
            }
            else if let value = value as? String {
                
                if let data = value.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                    
                    return self.setValue(json, forKey: key)
                    
                }
                    
            }
            
        }
        else {
            super.setValue(value, forKey: key)
        }
        
    }
    
    public override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
        if key == "id" || key == "userID" {
            
            if let id = value as? UInt {
                self.userID = id
            }
            
        }
        else {
            #if DEBUG
            print("User undefined key:\(key) with value:\(String(describing: value))")
            #endif
        }
        
    }
    
}

extension User {
    
    public override var description: String {
        let desc = super.description
        return "\(desc)\n\(dictionaryRepresentation)"
    }
    
    public var dictionaryRepresentation: [String: Any] {
        
        get {
                
            var dict = [String: Any]()
            dict["uuid"] = uuid
            dict["userID"] = NSNumber(integerLiteral: Int(userID))
            
            var filters = [String]()
            
            for filter in self.filters {
                filters.append(filter)
            }
            
            dict["filters"] = filters
            
            if let sub = subscription {
                dict["subscription"] = sub.dictionaryRepresentation
            }
            
            return dict
            
        }
        
    }
    
}

extension User: Copyable {}
