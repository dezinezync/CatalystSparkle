# v2.2.0

This build includes support for Local Syncing. If something breaks, the app crashes or does not work as expected, roll back to Build 85. 

Please run "Force Resync" or delete the app and install again before using the first time. 

## Known Issues 

- Searching in feeds may crash the app.

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
