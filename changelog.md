# v2.2.0

This build includes support for Local Syncing. If something breaks, the app crashes or does not work as expected, roll back to Build 85. 

Please run "Force Resync" or delete the app and install again before using the first time.

## Build 129 

- fixes dark mode for push request modal

## Build 128

- Fixes another bug with the Directional Marking Read feature.

- Fixes an issue for adding Youtube Channel feeds. Youtube recently changed their markup which was causing issues. 

## Build 127

- Push Notifications Request Form. If you already have push notifications enabled, you won't see this. This is per device. 

-  Includes support for background push notifications to keep all your devices in sync without needing manual refreshing. 

## Build 126

- Fixes directional marking read bug which caused all articles to get marked as read. h/t Gui. 

- Added Feeds to the iOS Search Index. You can now directly open feeds by their names (or custom names if you have one set). I'll eventually expand this to your bookmarks and other articles as well. 

## Build 125

- If you mark articles as read through the various modes and then shift the app to the background or switch to another app, the app now correctly syncs this information. Previously, this would not run until the app was brought to the foreground or if the app was terminated by the OS.  

- Preliminary support & implementation of local search based on the new local sync system. 

## Build 124 

- Fixes custom feeds not loading up when launching the app. 

## Build 123

- Fixes marking read across all feed views. 

- Improved performance of marking articles as read. Marking up to a 1000 articles now takes the same amount of time, CPU and battery resources as 10. 

- Marking articles as read or unread is now a coalesced to reduce network and battery usage. So it may sometimes take a second or two for changes to reflect across devices. An improvement around this should come in the next build next week.   

## Build 122

- Added context menu to the Full-Text button. Provides an option to delete the existing cache and to delete it and redownload (the latter option is useful when debugging for updated cache options).

## Build 121

- Improved performance for devices older than the A12 series when fetching, sorting and filtering articles inside feeds. 

- Improved performance for filtering articles.

- Improved accuracy of the unread counts across devices. 

- Removed the Mark all including back-dated articles option. Two mark read options were confusing. Now things are simpler. Just one. 

- macOS: Fixed a crash that would occur when Marking as Read inside a Folder view. 

## Build 120

- Added a context menu option to force-resync under Settings. Now you can also only force refresh the feeds and folders if the app goes out of sync on any device. 

- Fixed an issue where custom feed names were not immediately applied and would require an app-restart. Now, when you sync and new updates are available from other devices, the changes are applied immediately after syncing finishes. 

## Build 117

- Massively improved local filtering. Relative to the previous implementation, the new implementation is 300% faster. :D 

- Filtering is now stricter. It'll match "sponsor" but will not match "sponsored". 

- Fixed an issue with certain CJK paragraph blocks rendering incorrectly when certain linebreak characters are used in the paragraph text.  

- Fixed an issue with filters incorrectly hiding articles when matching against CJK based filters. 

- Fixed an issue with line-heights in the articles list for multi-lined article titles with favicons. 

- Fixed an issue where the "no articles" label would appear over the articles. 

- macOS: Fixes a long standing issue where the article's list would not draw a separator between two articles. 
