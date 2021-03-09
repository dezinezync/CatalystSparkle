//
//  FeedTests.swift
//  
//
//  Created by Nikhil Nigade on 04/03/21.
//

import XCTest
@testable import Models

final class FeedTests: XCTestCase {
    
    static let feedJSON: [String: Any]? = {
        guard let data = feedJSONString.data(using: .utf8) else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }()
    
    static func makeFeed () -> Feed {
        return Feed(from: Self.feedJSON!)
    }
    
    func testInitFromDict () {
        
        let feed = Self.makeFeed()
        
        XCTAssertEqual(feed.feedID, 1)
        XCTAssert(feed.summary.contains("Apple news"))
        XCTAssertEqual(feed.title, "MacStories")
        XCTAssert(feed.url.absoluteString.contains("/feed"))
        XCTAssertEqual(feed.rpcCount, 0)
        XCTAssertNil(feed.lastRPC)
        XCTAssertFalse(feed.hubSubscribed)
        XCTAssertEqual(feed.folderID, 0)
        XCTAssertNotNil(feed.extra)
        XCTAssertNotNil(feed.extra?.opengraph)
        XCTAssert(feed.canShowExtraLevel == true)
        XCTAssertEqual(feed.displayTitle, feed.title)
        
        feed.setValue("2021-03-04T00:00:00.000Z", forKey: "lastRPC")
        XCTAssertNotNil(feed.lastRPC)
        
    }
    
    func testEquality () {
        
        let feed = Self.makeFeed()
        
        let shallowCopy = Feed()
        shallowCopy.feedID = feed.feedID
        shallowCopy.url = feed.url
        
        XCTAssert(feed == shallowCopy)
        
        shallowCopy.feedID += 1
        
        XCTAssert(feed != shallowCopy)
        
        XCTAssert(feed != FeedMetaData())
        
    }
    
    func testDictRepresentation () {
        
        let feed = Self.makeFeed()
        
        let dict = feed.dictionaryRepresentation
        
        XCTAssertNotNil(dict["extra"])
        XCTAssertNotNil(dict["title"])
        XCTAssertNotNil(dict["url"])
        XCTAssertNotNil(dict["feedID"])
        
    }
    
    func testDescription () {
        
        let feed = Self.makeFeed()
        let desc = feed.description
        
        XCTAssert(desc.contains("Feed:"))
        XCTAssert(desc.contains("macstories.net"))
        
    }
    
    func testFaviconFromAppIcons () {
        
        let feed = Self.makeFeed()
        let icon = feed.faviconURI
        
        XCTAssertNotNil(icon)
        XCTAssertEqual(icon?.absoluteString, "https://www.macstories.net/app/themes/macstories4/images/apple-touch-icon-precomposed.png")
        
    }
    
    func testFaviconFromOpengraph () {
        
        guard let data = elytraExtraJSON.data(using: .utf8) else {
            fatalError("Invalid data from JSON string")
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            fatalError("Invalid JSON from data")
        }
        
        let feed = Feed()
        feed.url = URL(string: "https://elytra.app/blog/feed")
        feed.setValue(json, forKey: "extra")
        let icon = feed.faviconURI
        
        XCTAssertNotNil(icon)
        XCTAssertEqual(icon?.absoluteString, "https://blog.elytra.app/wp-content/uploads/2020/09/cropped-appicon.png")
        
    }
    
    func testFaviconFromFavicon () {
        
        guard let data = elytraExtraJSON.data(using: .utf8) else {
            fatalError("Invalid data from JSON string")
        }
        
        guard var json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            fatalError("Invalid JSON from data")
        }
        
        let feed = Feed()
        feed.url = URL(string: "https://elytra.app/blog/feed")
        feed.favicon = URL(string:"https://blog.elytra.app/wp-content/uploads/2020/09/appicon.png")
        
        json["opengraph"] = nil
        
        feed.setValue(json, forKey: "extra")
        let icon = feed.faviconURI
        
        XCTAssertNotNil(icon)
        XCTAssertEqual(icon?.absoluteString, "https://blog.elytra.app/wp-content/uploads/2020/09/appicon.png")
        
    }
    
    func testFaviconFromRelativeURL () {
        
        guard let data = elytraExtraJSON.data(using: .utf8) else {
            fatalError("Invalid data from JSON string")
        }
        
        guard var json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            fatalError("Invalid JSON from data")
        }
        
        let feed = Feed()
        feed.url = URL(string: "blog.elytra.app")
        feed.favicon = URL(string:"/wp-content/uploads/2020/09/appicon.png")
        
        json["opengraph"] = nil
        
        feed.setValue(json, forKey: "extra")
        let icon = feed.faviconURI
        
        XCTAssertNotNil(icon)
        XCTAssertEqual(icon?.absoluteString, "https://blog.elytra.app/wp-content/uploads/2020/09/appicon.png")
        
    }
    
    func testFaviconFromIcoURL () {
        
        let feed = Feed()
        feed.url = URL(string: "http://www.loopinsight.com/feed/")
        feed.setValue(loopJSON, forKey: "extra")
        let icon = feed.faviconURI
        
        XCTAssertNotNil(icon)
        XCTAssertEqual(icon?.absoluteString, "https://www.google.com/s2/favicons?domain=www.loopinsight.com")
        
    }
    
    func testFaviconFromAppIconWithQuery () {
        
        let feed = Feed()
        feed.url = URL(string: "https://topwithcinnamon.com/feed")
        feed.setValue(topWithCinnamonJSON, forKey: "extra")
        let icon = feed.faviconURI
        
        XCTAssertNotNil(icon)
        XCTAssertEqual(icon?.absoluteString, "https://topwithcinnamon.com/wp-content/uploads/fbrfg/android-chrome-192x192.png?v=XBqOdWp5jw")
        
    }
    
    func testFaviconForYoutubeFeed () {
        
        let feed = Feed()
        feed.url = URL(string: "https://www.youtube.com/feeds/videos.xml?channel_id=UCXuqSBlHAE6Xw-yeJA0Tunw")
        feed.setValue(lttJSON, forKey: "extra")
        let icon = feed.faviconURI
        
        XCTAssertNotNil(icon)
        XCTAssertEqual(icon?.absoluteString, "https://yt3.ggpht.com/a/AATXAJwQoPNwqUbfu_y7o7GWaeZgX8ovoHSYuWfbiJLR8g=s900-c-k-c0xffffffff-no-rj-mo")
        
    }

}

private let feedJSONString = "{\"id\":1,\"extra\":{\"opengraph\":{\"locale\":\"en_US\",\"type\":\"website\",\"title\":\"MacStories\",\"description\":\"Apple news, app reviews, and stories by Federico Viticci and friends.\",\"url\":\"https://www.macstories.net\",\"image\":\"https://56243e3f6f46fe44a301-deabeb5f3878e3553d0b065ea974f9bf.ssl.cf1.rackcdn.com/256px.png\"},\"apple-touch-icon\":{\"76\":\"https://www.macstories.net/app/themes/macstories4/images/apple-touch-icon-76x76-precomposed.png\",\"120\":\"https://www.macstories.net/app/themes/macstories4/images/apple-touch-icon-120x120-precomposed.png\",\"152\":\"https://www.macstories.net/app/themes/macstories4/images/apple-touch-icon-152x152-precomposed.png\",\"256\":\"https://www.macstories.net/app/themes/macstories4/images/apple-touch-icon-precomposed.png\"},\"feedlinks\":[\"https://www.macstories.net/feed/json/\",\"https://www.macstories.net/feed/\",\"https://www.macstories.net/?feed=articles-only\"],\"keywords\":[\"iOS\",\"iPhone apps\",\"iPad apps\",\"Mac applications\",\"OS X\",\"Apple news\",\"rumors\",\"MacStories\"],\"title\":\"MacStories\",\"feeds\":[{\"title\":\"MacStories » JSON Feed\",\"type\":\"application/feed+json\",\"url\":\"https://www.macstories.net/feed/json/\"},{\"title\":\"MacStories\",\"type\":\"application/rss+xml\",\"url\":\"https://www.macstories.net/feed/\"},{\"title\":\"MacStories — Articles Only\",\"type\":\"application/rss+xml\",\"url\":\"https://www.macstories.net/?feed=articles-only\"}],\"description\":\"Apple news, app reviews, and stories by Federico Viticci and friends.\",\"icon\":\"https://www.macstories.net/app/themes/macstories4/images/favicon.png\",\"url\":\"https://www.macstories.net\"},\"modified\":\"2020-10-13T06:12:35.000Z\",\"hubSubscribed\":0,\"hubLease\":null,\"subscribed\":false,\"url\":\"https://www.macstories.net/feed/json\",\"title\":\"MacStories\",\"rpcCount\":null,\"summary\":\"Apple news, app reviews, and stories by Federico Viticci and friends.\",\"podcast\":0,\"explicit\":0,\"created\":\"2017-11-13T04:43:43.000Z\",\"favicon\":\"\",\"hub\":null,\"lastRPC\":null,\"flags\":null,\"status\":1}"

private let elytraExtraJSON = """
{"feedlinks":["https://blog.elytra.app/feed/","https://blog.elytra.app/comments/feed/","https://blog.elytra.app/feed/json/"],"title":"Elytra | The simple RSS Reader. This blog publishes release notes, engineering and design details.","feeds":[{"title":"Elytra » Feed","type":"application/rss+xml","url":"https://blog.elytra.app/feed/"},{"title":"Elytra » Comments Feed","type":"application/rss+xml","url":"https://blog.elytra.app/comments/feed/"},{"title":"Elytra » JSON Feed","type":"application/feed+json","url":"https://blog.elytra.app/feed/json/"}],"description":"${data && data.description ? data.description : ''}","opengraph":{"locale":"en_GB","site_name":"Elytra","title":"Elytra","type":"website","image":"https://blog.elytra.app/wp-content/uploads/2020/09/cropped-appicon.png","description":"The simple RSS Reader. This blog publishes release notes, engineering and design details."},"url":"https://blog.elytra.app"}
"""

private let loopJSON: [String : Any] = [
    "url": "http://www.loopinsight.com",
    "title": "The Loop",
    "icon": "https://www.loopinsight.com/wp-content/themes/roots_dfll/favicon.ico",
    "description": "The Loop provides comprehensive and insightful news, editorial, and commentary on iPhone, iPod, Macintosh, associated third-party software and accessories,...",
    "keywords":
    [
        "iPad",
        "iPhone",
        "iPod",
        "Apple",
        "Mac",
        "Pro Tools",
        "Logic",
        "Guitar",
        "GarageBand",
        "Music Production",
        "The Loop"
    ]
]

private let topWithCinnamonJSON: [String: Any] = [
    "url": "https://topwithcinnamon.com",
    "title": "Izy Hossack - Top With Cinnamon - Flexitarian & Baking Recipes from Londoner, Izy Hossack",
    "feedlinks":
    [
        "https://topwithcinnamon.com/feed/",
        "https://topwithcinnamon.com/feed/atom/",
        "https://topwithcinnamon.com/feed/",
        "https://topwithcinnamon.com/comments/feed/"
    ],
    "feeds":
    [
        [
            "title": "Izy Hossack – Top With Cinnamon RSS Feed",
            "type": "application/rss+xml",
            "url": "https://topwithcinnamon.com/feed/"
        ],
        [
            "title": "Izy Hossack – Top With Cinnamon Atom Feed",
            "type": "application/atom+xml",
            "url": "https://topwithcinnamon.com/feed/atom/"
        ],
        [
            "title": "Izy Hossack - Top With Cinnamon » Feed",
            "type": "application/rss+xml",
            "url": "https://topwithcinnamon.com/feed/"
        ],
        [
            "title": "Izy Hossack - Top With Cinnamon » Comments Feed",
            "type": "application/rss+xml",
            "url": "https://topwithcinnamon.com/comments/feed/"
        ]
    ],
    "apple-touch-icon":
    [
        "16": "https://topwithcinnamon.com/wp-content/uploads/fbrfg/favicon-16x16.png?v=XBqOdWp5jw",
        "32": "https://topwithcinnamon.com/wp-content/uploads/fbrfg/favicon-32x32.png?v=XBqOdWp5jw",
        "36": "https://topwithcinnamon.com/wp-content/uploads/fbrfg/android-chrome-36x36.png?v=XBqOdWp5jw",
        "48": "https://topwithcinnamon.com/wp-content/uploads/fbrfg/android-chrome-48x48.png?v=XBqOdWp5jw",
        "57": "https://topwithcinnamon.com/wp-content/uploads/fbrfg/apple-touch-icon-57x57.png?v=XBqOdWp5jw",
        "60": "https://topwithcinnamon.com/wp-content/uploads/fbrfg/apple-touch-icon-60x60.png?v=XBqOdWp5jw",
        "72": "https://topwithcinnamon.com/wp-content/uploads/fbrfg/android-chrome-72x72.png?v=XBqOdWp5jw",
        "76": "https://topwithcinnamon.com/wp-content/uploads/fbrfg/apple-touch-icon-76x76.png?v=XBqOdWp5jw",
        "96": "https://topwithcinnamon.com/wp-content/uploads/fbrfg/android-chrome-96x96.png?v=XBqOdWp5jw",
        "114": "https://topwithcinnamon.com/wp-content/uploads/fbrfg/apple-touch-icon-114x114.png?v=XBqOdWp5jw",
        "120": "https://topwithcinnamon.com/wp-content/uploads/fbrfg/apple-touch-icon-120x120.png?v=XBqOdWp5jw",
        "144": "https://topwithcinnamon.com/wp-content/uploads/fbrfg/android-chrome-144x144.png?v=XBqOdWp5jw",
        "152": "https://topwithcinnamon.com/wp-content/uploads/fbrfg/apple-touch-icon-152x152.png?v=XBqOdWp5jw",
        "180": "https://topwithcinnamon.com/wp-content/uploads/fbrfg/apple-touch-icon-180x180.png?v=XBqOdWp5jw",
        "192": "https://topwithcinnamon.com/wp-content/uploads/fbrfg/android-chrome-192x192.png?v=XBqOdWp5jw"
    ],
    "icon": "https://topwithcinnamon.com/wp-content/uploads/fbrfg/favicon.ico?v=XBqOdWp5jw",
    "description": "Simple, delicious vegetarian meals and baking recipes",
    "opengraph":
    [
        "locale": "en_GB",
        "type": "website",
        "title": "Izy Hossack - Top With Cinnamon - Flexitarian & Baking Recipes from Londoner, Izy Hossack",
        "description": "Simple, delicious vegetarian meals and baking recipes",
        "url": "https://topwithcinnamon.com/",
        "site_name": "Izy Hossack - Top With Cinnamon"
    ],
    "manifest":
    [
        "name": "My app"
    ]
]

private let lttJSON: [String: Any] = [
    "url": "https://www.youtube.com/channel/UCXuqSBlHAE6Xw-yeJA0Tunw",
    "title": "Linus Tech Tips",
    "icon": "https://www.youtube.com/s/desktop/cd997a10/img/favicon.ico",
    "apple-touch-icon":
    [
        "32": "https://www.youtube.com/s/desktop/cd997a10/img/favicon_32.png",
        "48": "https://www.youtube.com/s/desktop/cd997a10/img/favicon_48.png",
        "96": "https://www.youtube.com/s/desktop/cd997a10/img/favicon_96.png",
        "144": "https://www.youtube.com/s/desktop/cd997a10/img/favicon_144.png"
    ],
    "feedlinks":
    [
        "https://m.youtube.com/channel/UCXuqSBlHAE6Xw-yeJA0Tunw",
        "https://m.youtube.com/channel/UCXuqSBlHAE6Xw-yeJA0Tunw",
        "https://www.youtube.com/feeds/videos.xml?channel_id=UCXuqSBlHAE6Xw-yeJA0Tunw",
        "android-app://com.google.android.youtube/http/www.youtube.com/channel/UCXuqSBlHAE6Xw-yeJA0Tunw",
        "ios-app://544007664/vnd.youtube/www.youtube.com/channel/UCXuqSBlHAE6Xw-yeJA0Tunw"
    ],
    "feeds":
    [
        [
            "title": "Untitled",
            "type": "application/rss+xml",
            "url": "https://m.youtube.com/channel/UCXuqSBlHAE6Xw-yeJA0Tunw"
        ],
        [
            "title": "Untitled",
            "type": "application/rss+xml",
            "url": "https://m.youtube.com/channel/UCXuqSBlHAE6Xw-yeJA0Tunw"
        ],
        [
            "title": "RSS",
            "type": "application/rss+xml",
            "url": "https://www.youtube.com/feeds/videos.xml?channel_id=UCXuqSBlHAE6Xw-yeJA0Tunw"
        ],
        [
            "title": "Untitled",
            "type": "application/rss+xml",
            "url": "android-app://com.google.android.youtube/http/www.youtube.com/channel/UCXuqSBlHAE6Xw-yeJA0Tunw"
        ],
        [
            "title": "Untitled",
            "type": "application/rss+xml",
            "url": "ios-app://544007664/vnd.youtube/www.youtube.com/channel/UCXuqSBlHAE6Xw-yeJA0Tunw"
        ]
    ],
    "description": "Tech can be complicated; we try to make it easy. Linus Tech Tips is a passionate team of \"professionally curious\" experts in consumer technology and video pr...",
    "keywords":
    [
        "Unboxing Review Computer Hardware Motherboard Intel AMD NVIDIA gaming"
    ],
    "opengraph":
    [
        "site_name": "YouTube",
        "url": "https://www.youtube.com/channel/UCXuqSBlHAE6Xw-yeJA0Tunw",
        "title": "Linus Tech Tips",
        "image": "https://yt3.ggpht.com/a/AATXAJwQoPNwqUbfu_y7o7GWaeZgX8ovoHSYuWfbiJLR8g=s900-c-k-c0xffffffff-no-rj-mo",
        "image:width": "900",
        "image:height": "900",
        "description": "Tech can be complicated; we try to make it easy. Linus Tech Tips is a passionate team of \"professionally curious\" experts in consumer technology and video pr...",
        "type": "profile",
        "video:tag": "gaming"
    ]
]
