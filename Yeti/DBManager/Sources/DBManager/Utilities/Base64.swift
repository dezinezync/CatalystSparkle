//
//  File.swift
//  
//
//  Created by Nikhil Nigade on 07/03/21.
//

import Foundation

extension String {
    
    func base64Encoded() -> String? {
        
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        
        return data.base64EncodedString()
        
    }
    
    func base64Decoded() -> String? {
        
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
        
    }
    
}
