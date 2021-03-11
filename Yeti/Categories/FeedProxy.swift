//
//  FeedProxy.swift
//  Elytra
//
//  Created by Nikhil Nigade on 11/03/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import Models

extension Feed {
    
    func faviconProxyURI(size: CGFloat) -> URL? {
        
        guard let favicon = faviconURI else {
            return nil
        }
        
        let path = favicon.absoluteString as NSString
        let proxyPath = path.path(forImageProxy: false, maxWidth: size, quality: 0.9)
        
        return URL(string: proxyPath)
        
    }
    
}
