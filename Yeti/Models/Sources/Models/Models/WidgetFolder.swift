//
//  WidgetFolder.swift
//  
//
//  Created by Nikhil Nigade on 17/04/21.
//

import Foundation

public struct WidgetFolder: Codable, Equatable {
    
    public var identifier: String
    public var displayString: String
    
    public init(title: String, folderID: UInt) {
        self.displayString = title
        self.identifier = "\(folderID)"
    }
    
    static public func == (lhs: WidgetFolder, rhs: WidgetFolder) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
}
