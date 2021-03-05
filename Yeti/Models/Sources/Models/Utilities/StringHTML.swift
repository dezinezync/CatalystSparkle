//
//  String+HTML.swift
//  
//
//  Created by Nikhil Nigade on 05/03/21.
//

import Foundation
import HTMLEntities

extension String {
    
    public func stripHTML() -> String {
        
        let raw = String(self).htmlUnescape()
        
        let scanner: Scanner = Scanner(string: raw)
        
        var convertedString = raw
        
        while !scanner.isAtEnd {
            let _ = scanner.scanUpToString("<")
            let text = scanner.scanUpToString(">") ?? ""
            convertedString = convertedString.replacingOccurrences(of: "\(text)>", with: "")
        }

        return convertedString
        
    }
    
}
