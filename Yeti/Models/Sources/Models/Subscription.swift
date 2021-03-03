//
//  Subscription.swift
//  
//
//  Created by Nikhil Nigade on 02/03/21.
//

import Foundation

enum SubscriptionEnv: String, Codable {
    case Sandbox
    case ProductionSandbox
    case Production
}

enum SubscriptionStatus: Int, Codable {
    case expired = 0
    case active = 1
    case trial = 2
}

class Subscription: NSObject, Codable {
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'.000Z'"
        formatter.timeZone = NSTimeZone.system
        return formatter
    }()
    
    var identifier: UInt!
    var environment: SubscriptionEnv!
    var expiry: Date! {
        didSet {
            
            guard expiry != nil else {
                status = .expired
                lifetime = false
                return
            }
            
            let components = Calendar.current.dateComponents([.era, .year, .month, .day], from: expiry)
            
            if components.year == 2025,
               components.month == 12,
               components.day == 31 {
                
                lifetime = true
                
            }
            
            let timeSinceNow = expiry.timeIntervalSinceNow
            
            status = timeSinceNow < 0 ? .expired : .active
            
        }
    }
    var created: Date!
    var status: SubscriptionStatus! = .expired
    var preAppStore: Bool = false
    var lifetime: Bool = false
    var external: Bool = false
    
    convenience init(from dict: [String: Any]) {
        
        self.init()
        
        setValuesForKeys(dict)
        
    }
    
    var hasExpired: Bool {
        get {
            if self.lifetime == true {
                return false
            }
            else if self.status == .expired {
                return true
            }
            else {
                
                guard let expiry = expiry else {
                    return true
                }
                
                let now = Date()
                let result = now.compare(expiry)
                
                return result != .orderedAscending
            }
        }
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        
        if key == "expiry" || key == "created" {
            
            var dateValue: Date? = nil
            
            if let val = value as? String {
                
                guard let date = Subscription.dateFormatter.date(from: val) else {
                    
                    return
                    
                }
                
                dateValue = date
                
            }
            else if let dateVal = value as? Date {
                
                dateValue = dateVal
                
            }
            
            if key == "expiry" {
                expiry = dateValue
            }
            else if key == "created" {
                created = dateValue
            }
            
            return
            
        }
        
        super.setValue(value, forKey: key)
        
    }
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
        if key == "id" || key == "identifier" || key == "identifer" {
            if let id = (value as? NSString)?.integerValue {
                identifier = UInt(id)
            }
        }
        else if key == "status", let value = value as? Int {
            
            status = SubscriptionStatus(rawValue: value)
            
        }
        else if key == "preAppStore" {
            
            preAppStore = value as! Bool
            
        }
        else if key == "environment", let value = value as? String {
            
            environment = SubscriptionEnv(rawValue: value)
            
        }
        else if key == "stripe" {
            
            var latest: [String: Any]
            
            if let stringVal = value as? String,
               let data = stringVal.data(using: .utf8),
               let items = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any],
               items.count > 0 {
                
                let descriptor = NSSortDescriptor(key: "current_period_end", ascending: true)
                
                var processed: [[String: Any]] = items.map { (object) in
                  
                    if let item = object as? String,
                       let itemData = item.data(using: .utf8),
                       let itemObj = try? JSONSerialization.jsonObject(with: itemData, options: []) as? [String: Any] {
                        
                        return itemObj
                        
                    }
                    
                    return object as! [String: Any]
                    
                }
                
                processed = (processed as NSArray).sortedArray(using: [descriptor]) as! Array
                
                latest = processed.last!
                
            }
            else if let dictVal = value as? [String: Any] {
                
                latest = dictVal
                
            }
            else {
                return
            }
            
            if let ending = latest["current_period_end"] as? Double {
                
                let endDate = Date(timeIntervalSince1970: ending)
                
                let timeSinceNow = endDate.timeIntervalSinceNow
                
                external = true
                expiry = endDate
                
                status = timeSinceNow < 0 ? .expired : .active
                
            }
            
        }
        
        #if DEBUG
        print("Subscription undefined key:\(key) with value:\(String(describing: value))")
        #endif
        
    }
    
}

extension Subscription {
    
    public var dictionaryRepresentation: [String: Any] {
        
        get {
                
            var dict = [String: Any]()
            dict["id"] = identifier
            dict["environment"] = environment.rawValue
            
            dict["expiry"] = Subscription.dateFormatter.string(from: expiry)
            dict["created"] = Subscription.dateFormatter.string(from: created)
            dict["status"] = status.rawValue
            dict["preAppStore"] = preAppStore
            dict["lifetime"] = lifetime
            dict["external"] = external
                        
            return dict
            
        }
        
    }
    
}

extension Subscription: Copyable {}
