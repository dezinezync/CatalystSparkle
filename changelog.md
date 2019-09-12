# iOS 13 Builds

This the RC build of Elytra v1.4 which will shipped using the GM Build of iOS 13 to Apple. Please report bugs immediately via email. Do not use Testflight to report issues. 

## Changes in Build 259  

Thanks to PD for reporting these.

- Fixes the typo in the Accounts Interface

- Fixes handling of nested italic and bold descriptors. Previously, only one of the two would be used (latest taking the priority).

## Changes in Build 258
- Fixes the layout for Image Loading Options Interface

- Fixes code snippests being displayed using the light style when dark mode is enabled.

## Changes in Build 257

- Fixed huge layout on iPads for the Recommendations Interface.

- Added new "Similar" section to the Recommendations. These are recommendations based on RSS Feeds you follow. If you and another person follow the same RSS Feed, Elytra will now show some feeds from that other person for you as a recommendation. These will be updated daily.

- Marking Read immediately updates the UI once again. Marking read in the Unread feed should now also reload a fresh batch if available. 

## Changes in Build 256
- Fixed code formatting issue causing HTML Entities to be escaped and decoded incorrectly. 

- Fixed the load next and load previous bug. 

## Changes in Build 255

- Fixed a crashing that could cause Tapping on "Rename" for a feed to crash the app. 

- Improved how Feed Renaming is handled by the app to ensure updates are immediately processed on screen. 

- Fixed the appearance of search results when tapping on a search result. 

## Changes in Build 254
- Tapping the Mercury button now shows an activity indicator when network I/O is in progress. 

- Fixes missing Rename Feed option from the context menus. 

- Elytra now supports Secure Coding for your bookmarks. This is a core change for the app which ensures reliability of the data. No UI affected. 

- Fixes keyboards not changing when changing the Scope when adding a new feed. This fix only applies to iOS 13. iOS 12 functions as expected. 

## Changes in Build 253
- Fixes the chances of the same image rendering twice in certain posts. 

## Changes in Build 252
- Disabled Drag and Drop on the Feeds Interface as it crashes immediately in iOS 13 Beta 5. 

- Corrected the loading of bookmarked articles offline on iOS 13. 

- Fixes copy behavior when highlighting text and then tapping on copy. This used a custom implementation since iOS 12.1.4 and I've finally found the issue and fixed it. Took over a year ¯\_(ツ)_/¯.

- Fixes the odd behaviour when lauching the app on an iPad would not show the sidebar. This required a custom implementation in iOS 12 to make it work correctly but is no longer needed for iOS 13 as of Beta 5. Hurray!

- Fixes sharing of URLs from articles after long tapping on the URL to bring up the Share Sheet. 

- Fixes the layout of the Accounts section. H/T. Anmol

- Account deactivation is now handled directly through the API. This no longer requires you to send an email to deactivate the account which further ensures your privacy.  

## Changes in Build 251
- Fixes a bunch of bugs coming from the Beta 5/ Public Beta 3 & 4 SDKs. App should be stable-r now. 

## Changes in Build 250
- fixes favicon issue in Feeds interface

- removes deferred processing for paragraphs as the memory bug from iOS 12.2 is now fixed in iOS 13 Beta 5.

- various sizing improvements for images and caching sized images

- the subscription expiry modal should not be dismissable

- fixes the height of Tweets embedded in articles. When no images are present in the tweet, the Tweet context adjusts to account for this. 

- improved Voice Over support for Lists, Ordered & Unordered variants. 
