# v2.2.0

This build includes support for Local Syncing. If something breaks, the app crashes or does not work as expected, roll back to Build 85. 

Please run "Force Resync" or delete the app and install again before using the first time. 

## Known Issues 

- Local sync may not fetch all of your bookmarks. 

- Opening "Today" section and "Folder" feeds may be slow on certain A9, A10, A10X and A11 powered devices. If you experience this, please contact me. 

- Searching in feeds may crash the app. 

## Build 111

- Improved sync performance. 

- Widgets are now updated considering the filters if you have any set up. 

- Filters are now processed when processing timelines. 

- Filters are now correctly updated locally when adding or removing filters. 

- macOS:  Force-Resync menu option for macOS. Hold option key before clicking on the Elytra Menu item in the menu bar. 

## Build 109

Other bugs and crash reports apart from these two: I'll look into them over the coming week. 

- This is a hot patch build which fixes a crash that would occur when the app is fetching updates. 

- This hot patch also fixes another related issue where the app would no longer fetch items from pending feeds until the next refresh is ready if the app had previously crashed. 

- This hotpatch also fixes an issue with incorrect updates to the read-articles from your other devices. 

## Build 106

- Fixed an issue where the app would stall or eventually crash (sometimes immediately) during initial or fresh sync. 

- Fixed an issue where the Today view would load twice in quick succession. 

- Unread counts in the Feeds View and the new Feed Title view should not correctly account for your filters. 

## Build 105

- Fixed: inside a feed, the context and right swipe Browser actions will also respect the reader mode setting. 

## Build 104

- Fixed articles not loading for certain feeds. 

- Fixed Today View not updating when opened after an app launch. 

- Fixed unread counts showing a small mismatch. (Filtered counts issue still exists. Some feeds may show counts of the articles which have been filtered out of the view.)

- Add a new "Title View" to individual feeds. This shows the Feed Info and two preferences at the moment: Push Notifications & Safari Reader Mode. These are per feed settings. Push notifications can either be real-time (functional) or near real-time (non-functional at the moment). 

## Build 100

- Fixed a crash when app is backgrounded. 

## Build 99 

- Fixed some feeds not getting synced. Uses the new caching mechanism instead to check feeds with changes. 

## Build 85

## Improvements

- Tapping on a folder now opens the folder's feed. 

- Tapping on the disclosure icon on a folder now toggles its expanded state. 

## Fixes

- Fixed the tint colour for the blog name when opening a micro-blog article. 

- Fixed adding feed by URL where the feed presents multiple options.

- Fixed an issue when searching by title for 3-letter sites like CNN or BBC. 

### macOS

- Added the "Contact Support" menu item under Help on macOS. 

- Fixed the activity indicator not being visible when opening a feed. 
