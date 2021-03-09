//
//  Folder.swift
//  
//
//  Created by Nikhil Nigade on 04/03/21.
//

import Foundation

public final class Folder: NSObject, Codable, ObservableObject {
    
    public var title: String!
    public var folderID: UInt!
    public var expanded: Bool = false
    public var feedIDs = Set<UInt>() {
        didSet {
            
            let _ = feedIDs.map { $0 }
            
            //TODO: get from FeedsManager and update it to feeds weak array
            
        }
    }
    
    public enum CodingKeys: String, CodingKey {
        case title
        case folderID
        case feedIDs
        case expanded
    }
    
    fileprivate enum AdditionalInfoKeys: String, CodingKey {
        case feeds
    }
    
    // https://stackoverflow.com/a/60707942/1387258
    public var feeds = [() -> Feed?]()
    
    // https://stackoverflow.com/a/59587459/1387258
    public var unread: UInt {
        return feeds.reduce(0) { (result: UInt, closure: @escaping () -> Feed?) -> UInt in
            return result + (closure()?.unread ?? 0)
        }
    }
    
    public convenience init(from dict: [String: Any]) {
        
        self.init()
        
        setValuesForKeys(dict)
        
    }
    
    public override func setValue(_ value: Any?, forKey key: String) {
        
        if key == "title", let value = value as? String {
            title = value
        }
        else if key == "id" || key == "folderID", let value = value as? UInt {
            folderID = value
        }
        else if key == "feeds", let value = value as? [UInt] {
            
            value.forEach { feedIDs.insert($0) }
            
        }
        else {
            super.setValue(value, forKey: key)
        }
        
    }
    
    public override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
        #if DEBUG
        print("Folder undefined key:\(key) with value:\(String(describing: value))")
        #endif
        
    }
    
}

extension Folder {
    
    public override var description: String {
        let desc = super.description
        return "\(desc)\n\(dictionaryRepresentation)"
    }
    
    public var dictionaryRepresentation: [String: Any] {
        
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
