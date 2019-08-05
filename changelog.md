# iOS 13 Builds

You can skip these builds if you're not running iOS 13. You will not notice any difference on iOS 12. If you do install these builds irrespective of the OS, these are some very early builds so please expect this to be buggy. You can always roll back to the AppStore version or a previous build from within Testflight.

## Changes in Build 252
- Disabled Drag and Drop on the Feeds Interface as it crashes immediately in iOS 13 Beta 5. 

- Corrected the loading of bookmarked articles offline on iOS 13. 

- Fixes copy behavior when highlighting text and then tapping on copy. This used a custom implementation since iOS 12.1.4 and I've finally found the issue and fixed it. Took over a year ¯\_(ツ)_/¯.

- Fixes the odd behaviour when lauching the app on an iPad would not show the sidebar. This required a custom implementation in iOS 12 to make it work correctly but is no longer needed for iOS 13 as of Beta 5. Hurray!

- Fixes sharing of URLs from articles after long tapping on the URL to bring up the Share Sheet. 

## Changes in Build 251
- Fixes a bunch of bugs coming from the Beta 5/ Public Beta 3 & 4 SDKs. App should be stable-r now. 

## Changes in Build 250
- fixes favicon issue in Feeds interface

- removes deferred processing for paragraphs as the memory bug from iOS 12.2 is now fixed in iOS 13 Beta 5.

- various sizing improvements for images and caching sized images

- the subscription expiry modal should not be dismissable

- fixes the height of Tweets embedded in articles. When no images are present in the tweet, the Tweet context adjusts to account for this. 

- improved Voice Over support for Lists, Ordered & Unordered variants. 

## Changes in Build 249
- Fixed the background sync issue which would crash Elytra.

- Fixed selecting the Default App Icon not working (H/T: Anmol)

- Fixed changing the Unread Counter option to crash the app (H/T: Anmol)

- The Refresh Control on iOS 13 is now tinted by iOS and not the app. (H/T: Anmol)

- Attributions Interface is now correctly rendered for your preference of Dark or Light UI. (H/T: Anmol)

- Fixes the wrong Keyboard interface showing for inputs throughout the app. (H/T: Anmol)

## Changes in Build 248
- QoL changes for Beta 3. 

- Known issue: Elytra will crash in the background when fetching updates for your Unread feed. I'll post a patch hopefully in the coming week to fix this issue.

## Changes in Build 247
- Fixes a crash which would sometimes occur after tapping the **Load GIF** Button.

- Fixes a crash which would sometimes occur when loading the Unread section when it has 0 unread items. 

## Changes in Build 246
- Fixed State Restoration. Works as expected now across app launches.

- Tapping on a selected theme no longer reloads themes.

- Improved the gamma point for Reader Theme (Dark and Light).

## Changes in Build 244
- Fixed Settings cells incorrectly rendering in some cases (the footer label bug persists in this build and is a known issue.)

- Using the new relative date formatter API from iOS 13 to print relative dates like "3 hours ago", "1 week ago" etc. It's actually faster than the previous implementation I was using. 

- Fixed cell colours for devices running iOS 12. 

## What's New
- **Dark Mode**: The app now integrates with iOS' Dark Mode and seamlessly adapts to the iOS' dark UI when you change the setting or when iOS does it automatically.
    The existing Dark theme has now been merged into the light theme which is now named *System*. The Black theme appears as is, irrespective of iOS' setting. It's always black.    
    
- **New Font**: A new font is available under Appearance Settings very aptly called, **Open Dyslexic**. It is now included in Elytra to encourage and assist dyslexics like myself to read without strain. 

- **New Icons**: Elytra now uses SF Symbols where ever applicable. I'm still working out scaling in certain places, if you notice something off, incorrect or have a suggestion, please message me. 

- **Contextual Menus**: The Folder, Feed and Article rows now provide contextual menus which Apple has used to replace the Peek and Pop Mechanism. 

## Improvements
- **Improved Memory Usage**: Using some new techniques in iOS 13, I've managed to shave off some significant memory usage from the app. I still have some spots to improve and clean up and that will further reduce the app's memory usage. 

### Known Issues
- **Launch Screen**: Sometimes, the launchscreen of the app may show a black bar at the top in the light theme mode. 

- **Settings Section**: Certain sections in Settings are rendered incorrectly and this is a bug in iOS 13. It should hopefully work better in the upcoming iOS Builds.
