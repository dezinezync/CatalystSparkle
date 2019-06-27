# iOS 13 Build
This is the very first iOS 13 build which aims to bring certain improvements to the system and match more closely with iOS 13. The aim of Elytra has always been to provide a seamless experience with the OS itself, deferring branding to the content.

You can skip these builds if you're not running iOS 13. You will not notice any difference on iOS 12. If you do install these builds irrespective of the OS, these are some very early builds so please expect this to be buggy. You can always roll back to the AppStore version or a previous build from within Testflight.

## Changes in Build 245
- Fixed State Restoration. Works as expected now across app launches.

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
