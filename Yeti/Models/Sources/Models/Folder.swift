//
//  Folder.swift
//  
//
//  Created by Nikhil Nigade on 04/03/21.
//

import Foundation

class Folder: NSObject, Codable, ObservableObject {
    
    var title: String!
    var folderID: UInt!
    var expanded: Bool = false
    var feedIDs = Set<UInt>() {
        didSet {
            
            let _ = feedIDs.map { $0 }
            
            //TODO: get from FeedsManager and update it to feeds weak array
            
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case title
        case folderID
        case feedIDs
        case expanded
    }
    
    // https://stackoverflow.com/a/60707942/1387258
    var feeds = [() -> Feed?]()
    
    var unread: UInt {
        return feeds.reduce(0) { (result: UInt, closure: @escaping () -> Feed?) -> UInt in
            return result + (closure()?.unread ?? 0)
        }
    }
    
    convenience init(from dict: [String: Any]) {
        
        self.init()
        
        setValuesForKeys(dict)
        
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        
        if key == "title", let value = value as? String {
            title = value
        }
        else if key == "id" || key == "folderID", let value = value as? UInt {
            folderID = value
        }
        else if key == "feedIDs", let value = value as? [UInt] {
            
            value.forEach { feedIDs.insert($0) }
            
        }
        else {
            super.setValue(value, forKey: key)
        }
        
    }
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
        #if DEBUG
        print("User undefined key:\(key) with value:\(String(describing: value))")
        #endif
        
    }
    
}

extension Folder {
    
    var dictionaryRepresentation: [String: Any] {
        
        var dict = [String: Any]()
        
        dict["feedIDs"] = feedIDs.map { $0 }
        dict["id"] = folderID
        
        if let title = title {
            dict["title"] = title
        }
        
        dict["expanded"] = expanded
        
        return dict
        
    }
    
}

extension Folder: Copyable { }
