# v2.3.0

### Build 217

- Fixed an issue with the widgets not updating correctly. 

- Fixed an issue with the Folders widget not updating currently when the app is resumed from the background. 

- Fixed an issue with the Folders widget crashing when no articles were present. 

- Improved layout for Folders widget. 

### Build 216

- Added two new widgets: Bloccs & Folders. 

    Folders Widget lets you select a specific folder from your list and will show all unread articles from that folder. Please launch the app once before selecting a folder and then run the app once to update the data for the widget.
    
- Fixed an underlying issue where Headers would not be rendered. 

- Fixed an issue where opening an article from a widget would not mark it as read and additionally render is incompletely if it's a Youtube video. 

- Rename feed should show original title if no custom name is set. 

### Build 211

- Improved overall rotation logic on iPadOS.

- Fixed an issue with the Unreads Widget not updating correctly. 

- Fixed an issue with the Unreads Widget preferences not functioning correctly. 

- Fixed portrait orientation setups for iPadOS. 

### Build 210

- Fixes a bug where the summary would contain incomplete text or html. 

- Fixed a regression from Build 208/209 where separators would not show between articles. 

- Fixed a bug where counters would not update on folders. 

### Build 209

- Fixed a rare issue where the folders would map the feeds but would display them outside the tree. 

- Fixed toolbar not being setup for the articles list when using the Toolbar preference. 

- Fixed the previous/next buttons in the Article Reader toolbar being disabled incorrectly. 

### Build 208

- Fixed an issue where Articles were not formatted correctly. Links, italics and bold formatting were stripped from the articles.

- Fixed a rare crash during sync. 

### Build 205

- Fixed sync not working correctly upon Signing Up for the first time. 

- Fixed folder feeds not filtering content based on Filters. 

- Fixed a crash on launch when counting unread items a in folder.

### Build 204

- Fixed an issue with counters not updating in certain cases. 

- Fixed an issue with the "Start Trial" button not doing anything. 

- Fixed an issue with read articles appearing when the Unread Sorting is applied. This would happen when no filters are set up.  

### Build 203

- Fixes sorting for Folders and Author Feeds.

- Fixes updating titles for Unread & Today Feeds. 

- Fixes an issue with some articles not being downloaded correctly. 

- New interaction: You can now long tap (on iOS/iPadOS, or right click on macOS ) on the article title inside the reader to reload the article. Use this sparingly and only when needed. 

Additional bug fixes will come in a following build. 

### Build 201

- iPadOS: Shows sidebar on launch in portrait mode. 

- Updated licenses.

The app will do a full resync on first launch. If the app crashes for you, please reset the app from the Settings app (or delete and install again) and setup again.  

## New 

- New Flow for adding new feeds. 

- New Flow for exploring topics and recommendations. Recommendations has been removed from the app. 

- Improved adding feeds from the share extension. 

- Improved the underlying engine for improved efficiency and resilency. 

- Improved performance on devices like the iPhone 7, iPad Air 2, iPad 5 and others. 

- Improved power efficiency over the previous v2.x builds. 

### May not work

- Background notifications may sometimes not work or crash the app in the background. 

### Will not work

- Import and Exporting OPML files will not work at the moment. This will be patched soon. 

- Switching for a custom Account ID to an Apple ID will not work at the moment. This will be patched soon. 

- Switching between custom IDs will not work at the moment. This will be patched soon. 
