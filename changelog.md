# v1.8.0

This is the RC 1 build for v1.8.

## Build 368

- Improved scroll pagination. 

- Various improvements for better state restoration using the newer iOS APIs. 

## Build 367

- Fixes bookmarking and unbookmarking articles. 

- Fixes bookmarks count not updating in real-time. 

- Fixes removing a bookmark would have no net-effect. 

- Bookmarks List no longer shows a persistent bookmark icon. It instead now correctly defers to the Article's read status.

## Build 366

- Hiding bars on scroll in the Article Reader is now a preference under Settings > Misc. It is now disabled by default. 

- Fixed the Dark app icon rendering incorrectly when used. 

## Build 365 

- Fixed loading articles after tapping a Push Notification.

- Fixes showing cover images in rich push notifications.

## Build 364

- New App Icon

- New App Icon Sets (under Settings > Misc. > App Icons)

- Article Readers bars now auto-hide/show on scroll deferring more screen real-estate to the content. 

## Build 363

- Fixes loading of some favicons. 

- Fixes reloading of stale data in some cases. 

## Build 362

- If the source supports it, the separate "dark mode" image will be used when available. 

- Background Refresh now uses Apple's new API released in iOS 13.  

- A new controller which shows your Articles. You can now search for articles which have been loaded locally and on the server as well. The server option will only match titles,  keywords and author names whereas the local version will only match the author and article's title. 

- The recommendations view is now shown inline. 

- A new horizontal two finger swipe gesture for iPadOS to show and hide the Feeds Interface. This works globally.  

- Fixes some leaks caused when loading images over the network. 

- The app should now use much less RAM (in most cases, 50% less memory). 

- The app should now consume approx. 10% less power when in foreground. 

- Added Swipe Actions to Article List items. 

- New Contextual Action for articles: "View articles by Author". Quickly lets you view all articles by a particular author. 
