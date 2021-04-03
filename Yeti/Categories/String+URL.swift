//
//  String+URL.swift
//  Elytra
//
//  Created by Nikhil Nigade on 19/02/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation

private let urlMatchRegex = "((http|https|ftp)://)?((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+"

extension String {
    
    // https://stackoverflow.com/a/57219660/1387258
    
    var isValidURL: Bool {
        
        if let _ = URL(string: self) {
            return true
        }
        
        return false
        
//        let predicate = NSPredicate(format: "SELF MATCHES %@", urlMatchRegex)
//        return predicate.evaluate(with: self)
        
    }
    
}
