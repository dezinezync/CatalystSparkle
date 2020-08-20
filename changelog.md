# v2.0.0

## Build 7

- Images are once again openable in fullscreen mode.

- Preliminary Widgets support. Contains a Counters (Small) Widget and a Unread Articles (medium and large) widget. 

## Build 6

- Implements Trailing Swipe actions on Feed Cells.

- Fixes marking articles as read in bulk locking up the app. 

- Fixes an issue where marking currently loaded articles as read in the Unread view would prevent new articles from loading.  

- Selecting the Custom Feeds now updates their selected state similar to regular feeds. 

- If you have setup a custom title for a Feed, the custom title will now show up correctly for the empty state. 

- Fixed a crash caused when trying to share a Feed's URL or its website's URL.

## Build 5

- Prevents an issue causing the app to sync data twice upon successfully launching. 

- Fixes the icons layout issue from **Build 3** causing   
    - Icons to be incorrectly sized in a lot of cases 
    - Icons of one feed to be applied to a different feed 

- Moves Folder Feed access to the Folder's context menu. (No way to detect a tap right now on the Folder's row.)

- Reliably updates Folder and Feed unread counts. 

## Build 3

- All new triple column support using Apple's own UI Framework. This is much more reliable that my own implementation from v1. 

- An all new Sidebar Interface. This uses Apple's latest UI Framework for displaying your folders and feeds. 

- Unread counts update more reliabily as you read through your content. 

- Improved underlying code for managing the initial state of the app. 

### Known Issues & Other Notes

- Custom theme settings may not apply to the new Sidebar VC. Custom theming will be removed in a future update. 

- No changes to the Articles List or Article Renderer in this update.  
