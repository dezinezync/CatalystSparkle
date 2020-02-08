# v1.6

## Build 317 

- Re-add WebP Images support.
 
- Improved handling of opening articles from push notifications.  

- Blog Names below the Article's title are now tappable. They open the blog's article's list. When you open an article from the blog's own article list, this behaviour is disabled to prevent a rabbit hole situation. 

- Minor QoL adjustments and rendering improvements. 

- Fixed opening an Feed from the search results. 

- Improved loading Youtube Videos. The HLS Manifest of the video is now loaded when available. If this is absent, then the mp4 file is checked for and loaded if available. Using the HLS Manifest improves battery usage, performance and lowers data usage. The HLS Manifest is directly handled by the OS and hence also respects Low Data modes on your WiFi or Cellular connections.  

## Build 316
- Moving from open to open folder no longer crashes the app. 

## Build 315

- Keyboard commands are now available once again. **KNOWN ISSUE**: Once you open an article, the keyboard commands for the Feeds Interface may not work in certain cases. 

- Fixed the default sorting option for Unread showing the wrong icon. 

- Improved legibility and visibility of a couple of icons. 

- Fixed rendering on the launch splash screen. 

- Fixed displaying article helper view on larger iPhones.

## Build 313

- Introduces the new triple column layout for iPads in Landscape mode. 

- Deprecated support for iOS 12. 

- fixes iOS 13 link tap bug: when scrolling in the article reader, if your finger scrolls by dragging a link, iOS would tell the app to open that link. 

- fixes Search Bar not toggling in view.

- fixes Search previous button being enabled when viewing the first search result in the article. 
