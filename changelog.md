# v1.4.1

##  Build 265

- Fixed favicon scaling issue in the New Feed Interface

- Removed some extra code for scaling images (the code checked if the image was cached, twice!).

- Fixed the activity indicator not being visible when using dark mode (black backgrounds dont show black acitivty indicators easily, ya know!)

##  Build 264

- Fixed a crash that would occur on iOS 13 if you opened a folder when feeds were updating in the background. 

- Uses the new Link Previews to show Tweets.

##  Build 262

- Fixed a range overflow bug which occurred when an HTML element's text content was trimmed but the attributes range was not adjusted for the same. 

- Fixed opening articles from notifications. 

- Tapping buy without a valid product selected no longer crashes the app. 

- Fixed a rendering bug for Youtube video cover images which did not respect the source aspect ratio.  
