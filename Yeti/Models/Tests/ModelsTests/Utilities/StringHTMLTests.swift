//
//  File.swift
//  
//
//  Created by Nikhil Nigade on 05/03/21.
//

import XCTest
@testable import Models

final class StringHTMLTests: XCTestCase {
    
    func testStrippingHTML() {
        
        let html = "<p>Elytra brings Native Text Rendering for RSS Feeds which enables iOS’ VoiceOver, Dynamic Type support and several <em>Accessibility Features</em>.</p>"
        
        let plainText = html.stripHTML()
        
        XCTAssertEqual(plainText, "Elytra brings Native Text Rendering for RSS Feeds which enables iOS’ VoiceOver, Dynamic Type support and several Accessibility Features.")
        
    }
    
    func testNestedHTML() {
        
        let html = String(nestedHTML)
        
        let plainText = html.stripHTML()
        
        XCTAssertEqual(plainText.count, 3785)
        
    }
    
    func testSimplePerformance() {
        
        let html = "<p>Elytra brings <strong><em>Native Text Rendering</em></strong> for RSS Feeds which enables iOS’ VoiceOver, Dynamic Type support and several <em>Accessibility Features</em>.</p>"
        
        measure {
            
            let plainText = html.stripHTML()
            
            XCTAssertEqual(plainText, "Elytra brings Native Text Rendering for RSS Feeds which enables iOS’ VoiceOver, Dynamic Type support and several Accessibility Features.")
            
        }
        
    }
    
    func testNestedPerformance() {
        
        let html = String(nestedHTML)
        
        measure {
            
            let plainText = html.stripHTML()
            
            XCTAssertEqual(plainText.count, 3785)
            
        }
        
    }
    
}

private let nestedHTML = """
<article id="post-472" class="post-472 post type-post status-publish format-standard hentry category-macos category-notes category-public category-release category-webservice">
<h1 class="entry-title">Elytra Winter 2020 Update</h1><div class="entry-meta"></div><!-- .entry-meta -->

<div class="entry-content">
<p>The Winter 2020 update is finally ready in 2021! This is the first release of Elytra which brings local sync, local notifications and a lot of performance and stability improvements to the apps.</p>
<p>Similar to Elytra v2 and v2.1, this is an iOS 14 only release. The latest supported version for iOS 13 is v1.8 and will be deprecated soon.</p>
<p>You can download the update from the <a href="https://apps.apple.com/us/app/id1433266971">App Store</a>. If you feel generous and have a couple of minutes, please leave a review on the App Store. It makes a huge difference for me. Thank you in advance.</p>
<h2 id="localsync">Local Sync</h2>
<picture><source media="(min-width: 769px)" srcset="https://blog.elytra.app/wp-content/uploads/2021/01/elytra-v2.2.png 1x, https://blog.elytra.app/wp-content/uploads/2021/01/elytra-v2.2@2x.png 2x"><source media="(min-width: 481px) and (max-width: 768px)" srcset="https://blog.elytra.app/wp-content/uploads/2021/01/elytra-v2.2-768w.png 1x, https://blog.elytra.app/wp-content/uploads/2021/01/elytra-v2.2-768w@2x.png 2x"><source media="(max-width: 480px)" srcset="https://blog.elytra.app/wp-content/uploads/2021/01/elytra-v2.2-480w.png 1x, https://blog.elytra.app/wp-content/uploads/2021/01/elytra-v2.2-480w.png 2x"><img src="https://blog.elytra.app/wp-content/uploads/2021/01/elytra-v2.2.png" alt="Elytra v2.2 running on Macbook Air, iPhone XS and iPad Air" width="890" height="418/" pagespeed_url_hash="688132162" onload="pagespeed.CriticalImages.checkImageForCriticality(this);">
</picture>This release brings Local Sync to the apps. Local Sync caches all articles across all your feeds (just like other RSS Feed Reader Apps). This is not a <em>“new”</em> technique. Feed Reader apps have been doing this for as long as I can remember. Elytra now uses the same technique by leveraging its APIs to make the entire process a lot faster!<p></p>
<p>Elytra does not have to check every single feed if it has new updates. It uses a single API to check if updates are present, and if they are, sync them to your devices.</p>
<h2 id="fullchangelog">Full Change Log</h2>
<h3 id="new">New</h3>
<ul>
<li>Local Sync. All feeds are now synced to your device locally, so you can continue reading even when your device is offline.</li>
<li>Added a new “Title View” to individual feeds. Open a feed and tap on its title. This shows the Feed Info and two preferences at the moment: Push/Local Notifications &amp; Safari Reader Mode. These are per feed settings. This is very similar to the design and functionality from <a href="https://netnewswire.com">NetNewsWire</a>, is directly inspired by it, but with a minor difference: the layout and copy denotes which feeds support Push Notifications, while the others supporting Local Notifications.</li>
<li>Push Notifications Request Form. If you already have push notifications enabled, you won’t see this. This is per device.</li>
<li>Added support for background push notifications to keep all your devices in sync without needing manual refreshing.</li>
<li>Push Notifications for new articles now download and cache the article for immediate use.</li>
</ul>
<h3 id="improvements">Improvements</h3>
<ul>
<li>Tapping on a folder now opens the folder’s feed.</li>
<li>Tapping on the disclosure icon on a folder now toggles its expanded state.</li>
<li>Filtering is now stricter. It’ll match “sponsor” but will not match “sponsored”.</li>
<li>Added Feeds to the iOS Search Index. You can now directly open feeds by their names (or custom names if you have one set).</li>
</ul>
<h3 id="fixes">Fixes</h3>
<ul>
<li>Fixed the tint colour for the blog name when opening a micro-blog article.</li>
<li>Fixed adding feed by URL where the feed presents multiple options.</li>
<li>Fixed an issue when searching by title for 3-letter sites like CNN or BBC.</li>
<li>Fixed articles not loading for certain feeds.</li>
<li>Fixed Today View not updating when opened after an app launch.</li>
<li>Fixed an issue with the iPadOS app showing different widths for the columns in different orientations or environments (split view).</li>
<li>Fixed an issue with the apps not correctly download bookmarks from the API.</li>
<li>Fixed an issue where toggling folders in the sidebar interface would show empty folders.</li>
<li>Fixed an issue with certain CJK paragraph blocks rendering incorrectly when certain linebreak characters are used in the paragraph text.</li>
<li>Fixed an issue with filters incorrectly hiding articles when matching against CJK based filters.</li>
<li>Fixed an issue with line-heights in the articles list for multi-lined article titles with favicons.</li>
<li>Fixed an issue where the “no articles” label would appear over the articles.</li>
<li>Fixed an issue for adding Streaming Video Channel feeds. They recently changed their format which was causing issues.</li>
<li>Fixed a crash when writing the widgets data to disk when the app has just been sent to the background.</li>
<li>Fixed Navigation Bar buttons not appearing in some contexts.</li>
</ul>
<p>Thank you for reading.</p>
</div><!-- .entry-content -->

<footer class="entry-footer"><span class="cat-tags-links">Posted in: <a href="https://blog.elytra.app/category/macos/" rel="category tag">macOS</a>, <a href="https://blog.elytra.app/category/notes/" rel="category tag">notes</a>, <a href="https://blog.elytra.app/category/public/" rel="category tag">public</a>, <a href="https://blog.elytra.app/category/release/" rel="category tag">release</a>, <a href="https://blog.elytra.app/category/webservice/" rel="category tag">webservice</a></span></footer> <!-- .entry-footer --><div class="entry-meta"><span class="posted-on"><span class="screen-reader-text">Posted on</span> <a href="https://blog.elytra.app/2021/01/25/elytra-winter-2020-update/" rel="bookmark"><time class="entry-date published updated" datetime="2021-01-25T09:00:05+05:30">25/01/2021</time></a></span><span class="byline"> by <span class="author vcard"><a class="url fn n" href="https://blog.elytra.app/author/user/">Nikhil</a></span></span></div></article>
"""
