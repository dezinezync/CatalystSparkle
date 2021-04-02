//
//  Defaults+Elytra.swift
//  Elytra
//
//  Created by Nikhil Nigade on 21/03/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import Defaults

func dispatchMainAsync(_ callback: (() -> Void)?) {
    
    guard let cb = callback else {
        return
    }
    
    guard Thread.isMainThread == true else {
        
        DispatchQueue.main.async {
            cb()
        }
        
        return
        
    }
    
    cb()
    
}

extension Defaults.Keys {
    static let feedSorting = Key<FeedSorting.RawValue>("feedSorting", default: FeedSorting.descending.rawValue)
    //            ^            ^                        ^                      ^
    //           Key          Type                      UserDefaults name      Default value
    
    
    static let pushRequest = Key<Bool>("pushRequest", default: false)
    
    static let hasShownIntro = Key<Bool>("hasShownIntro", default: false)
    
    static let browserOpenInBackground = Key<Bool>("macKeyOpensBrowserInBackground", default: false)
    
    static let externalTwitterApp = Key<String>("externalapp.twitter", default: "Twitter")
    
    static let externalRedditApp = Key<String>("externalapp.reddit", default: "Reddit")
    
    static let externalBrowserApp = Key<String>("externalapp.browser", default: "Safari")
    
}
