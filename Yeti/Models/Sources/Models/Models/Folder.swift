//
//  Folder.swift
//  
//
//  Created by Nikhil Nigade on 04/03/21.
//

import Foundation
import Combine
import BetterCodable

@objcMembers public final class Folder: NSObject, Codable, ObservableObject {
    
    public var title: String!
    public var folderID: UInt!
    public var feedIDs: [UInt] = [UInt]()
    
    public enum CodingKeys: String, CodingKey {
        case title
        case folderID = "id"
        case feedIDs = "feedIDs"
    }
    
    public var updatingCounters: Bool = false {
        willSet {
            if updatingCounters == true,
               newValue == false {
                updateCounters()
            }
        }
    }
    
    public var feeds: [Feed] = [] {
        didSet {
            
            if feedsUnread != nil {
                feedsUnread.cancel()
                feedsUnread = nil
            }
            
            feedsUnread = Publishers.MergeMany(feeds.map { $0.$unread })
                .receive(on: DispatchQueue.global())
                .sink { [weak self] _ in
                    
                    guard let sself = self else {
                        return
                    }
                    
                    guard sself.updatingCounters == false else {
                        return
                    }
                    
                    sself.updateCounters()
                    
                }
            
        }
    }
    
    // https://stackoverflow.com/a/59587459/1387258
    fileprivate var feedsUnread: AnyCancellable!
    
    @Published public var unread: UInt = 0
    
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
            
            value.forEach { feedIDs.append($0) }
            
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
        
        var dict: [String: Any] = [:]
        
        dict["feedIDs"] = feedIDs.map { $0 }
        dict["id"] = folderID
        
        if let title = title {
            dict["title"] = title
        }
        
        return dict
        
    }
    
    public func updateCounters () {
        // @TODO: Check why this crashes sometimes with GPFLT
        let value = self.feeds.reduce(0) { counter, newValue in
            counter + newValue.unread
        }
        
        unread = value
        
    }
    
}

extension Folder: Copyable { }
