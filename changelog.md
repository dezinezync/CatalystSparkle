# v2.2.0

This build includes support for Local Syncing. If something breaks, the app crashes or does not work as expected, roll back to Build 85. 

## Known Issues
- Local sync sometimes will not update a specific feed. If that happens, please let me know the feed's name which did not update. Or share the feed URL. 

- Local sync at the moment does not consider your mute filters when counting unread items. 

- Local sync may not fetch all of your bookmarks. 

- Opening "Today" section and "Folder" feeds may be slow on certain A9, A10, A10X and A11 powered devices. If you experience this, please contact me. 

- Searching in feeds may crash the app. 

## Build 103

- Fixed articles not loading for certain feeds. 

- Fixed Today View not updating when opened after an app launch. 

- Fixed unread counts showing a small mismatch. (Filtered counts issue still exists. Some feeds may show counts of the articles which have been filtered out of the view.)

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
