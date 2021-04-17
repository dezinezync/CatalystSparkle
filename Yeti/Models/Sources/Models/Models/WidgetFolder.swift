//
//  WidgetFolder.swift
//  
//
//  Created by Nikhil Nigade on 17/04/21.
//

import Foundation

public struct WidgetFolder: Codable {
    
    public var title: String
    public var folderID: UInt
    
    public init(title: String, folderID: UInt) {
        self.title = title
        self.folderID = folderID
    }
    
}
