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

enum RefreshIntervalKeys: String, Codable {
    case manually = "Manually"
    case halfHour = "Every 30 minutes"
    case oneHour = "Every Hour"
    
    var interval: Double {
        switch self {
        case .halfHour:
            return 30
        case .oneHour:
            return 60
        default:
            return 0
        }
    }
    
}

extension Defaults.Keys {
    static let feedSorting = Key<FeedSorting.RawValue>("feedSorting", default: FeedSorting.descending.rawValue)
    //            ^            ^                        ^                      ^
    //           Key          Type                      UserDefaults name      Default value
    
    static let unreadFeedSorting = Key<FeedSorting.RawValue>("unreadFeedSorting", default: FeedSorting.unreadDescending.rawValue)
    
    static let pushRequest = Key<Bool>("pushRequest-2.3.0", default: false)
    
    static let hasShownIntro = Key<Bool>("hasShownIntro", default: false)
    
    static let browserOpenInBackground = Key<Bool>("macKeyOpensBrowserInBackground", default: false)
    
    static let externalTwitterApp = Key<String>("externalapp.twitter", default: "Twitter")
    
    static let externalRedditApp = Key<String>("externalapp.reddit", default: "Reddit")
    
    static let externalBrowserApp = Key<String>("externalapp.browser", default: "Safari")
    
    static let showUnreadCounts = Key<Bool>("unreadCountPreferenceChanged", default: true)
    
    static let badgeAppIcon = Key<Bool>("badgeAppIconPreference", default: false)
    
    static let useToolbar = Key<Bool>("com.dezinezync.elytra.useToolbar", default: false)
    
    static let previewLines = Key<Int>("com.dezinezync.elytra.summaryPreviewLines", default: 0)
    
    static let hideBookmarks = Key<Bool>("com.dezinezync.elytra.hideBookmarksTab", default: false)
    
    // Mark: - macOS
    static let refreshFeedsInterval = Key<String>("macKeyRefreshFeeds", default: RefreshIntervalKeys.manually.rawValue)
    
}
