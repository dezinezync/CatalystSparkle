# v1.5.0

## Build 289
- fixed linked images which would not render if they were contained inside an anchor blog with multiple other elements. These other elements were usually linebreaks preventing the entire block from rendering properly. Affected blog: Saturday Morning Breakfast Cereal.

- The app now shows an alert when Sign in with Apple fails with the relevant error message from the OS. 

- Removed webp support. 

## Build 285

- Images are loaded using the same extension from the proxy as the source image. 

- Fixes a small bug with the unread count when marking read automatically from the article reader. 

## Build 283

- Drastically improved managing of unread counts in the app. 

- Improved behavior of the app when marking backdated articles as read. 

## Build 282
- Fixed an issue with image loading preferences. "Never Load Images" now works properly in the Articles List & Article Viewer.  

## Build 281
- Fixed some really nasty memory leaks.  

## Build 278

- **NEW** Image Viewer: Tap on an image in an article to open it in a full screen image viewer. All images from the article are gathered in single place for easier viewing. 

- Fixed a crash that would occur when launching the app. This was a regression introduced in Build 275 of Elytra and OS 13.1.2.

## Build 275

- Sign in With Apple. If you're new to Elytra, you don't need to take any additional steps. If you are new to Elytra, please head over to Settings > Account and link your account from there. 

- Micro.blog posts with images now show the image as a thumbnail in the articles list when settings are enabled for it. 

- Added a new Bookmarks Manager. This is much more efficient system compared to the previous system and is much more scalable.

- Fixed the colour of the summary label (iOS 13 only, correct on iOS 12). 
