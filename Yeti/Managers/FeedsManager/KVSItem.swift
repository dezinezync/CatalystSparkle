//
//  KVSItem.swift
//  Elytra
//
//  Created by Nikhil Nigade on 30/11/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

import UIKit

@objc enum KVSChangeType : Int {
    case Read = 0
    case Unread = 1
    case Bookmark = 2
    case Unbookmark = 3
}

@objc final class KVSItem: NSObject {
    
    @objc public var changeType: KVSChangeType = .Read
    @objc public var value: Bool = false
    @objc public var identifiers: [NSNumber] = []
    
    static func ==(lhs: KVSItem, rhs: KVSItem) -> Bool {

        return lhs.changeType == rhs.changeType && lhs.identifiers == rhs.identifiers

    }

}
