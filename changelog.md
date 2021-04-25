# v2.3.0

### Build 223

- Fixed marking items read. There was a bug introduced in v2.2 which sometimes caused marking articles as read to fail on the API but still marked it locally on your device. Moving forward, all your devices should be in sync. It is recommended you do a Force-Resync after installing the app to get the latest states from the API.

### Build 222

- Moved OPML Import/Export to its window on macOS.

### Build 220

- Import/Export OPML is now enabled and functional. 

- Fixes crash on tap.

### Build 219

- Fixed loading of images from Substack posts ( encased by cdn.substack.com in their newsletter posts). 

- Fixed a sync bug that would cause syncing to get stuck a particular position. 

- macOS: Fixed a nasty scrolling bug from macOS 11.2 onwards (against iOS 14.3).

- Articles with no reference to a feed will no longer render as empty rows. 

- Fixed the folders widget showing the same article twice in some cases. 

- Fixed widgets updating less aggressively. They would exhaust their updates quota and iOS would stop updating them until the next day. 

### Build 218

- Minor QoL improvements. 

- Fixed text alignment in the Push Notifications interface under Settings. 

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

### May not work

- Background notifications may sometimes not work or crash the app in the background. 

### Will not work

- Import and Exporting OPML files will not work at the moment. This will be patched soon. 

- Switching for a custom Account ID to an Apple ID will not work at the moment. This will be patched soon. 

- Switching between custom IDs will not work at the moment. This will be patched soon. 
