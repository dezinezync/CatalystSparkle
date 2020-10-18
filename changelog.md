# v2.1.0

## Build 63

- Fixed loading of GIF favicons

- Fixed setting up bookmarked state in DBManager’s articles collection 

- Fixed spelling of the Atkinson font under the Apperances Interface

## Build 62

- Toolbar is correctly hidden for the Feeds Interface when "Use Toolbars" preference is set. 

- Fixed a rendering issue for entire blocks wrapped inside a link. 

## Build 61

- Added the Atkinson Hyperlegible Font for Paragraph text and Titles. 

- For iPads in Portrait mode, selecting an article will now dimiss the overlay view. 

## Build 59

- Fixed a rare bug that would prevent the bookmarks counter from updating when adding or removing bookmarks. 

- Removing a bookmark while in the bookmarks feed now removes the article after a small delay. 

## Build 58

- Fixed a rare crashing bug that would occur when initating a Refresh in the Feeds Interface. (Thank you for Lee.)

## Build 57

- Fixed an issue with the Today Count always reporting as 1. 

- Fixed a rare crash that would occur in TF builds if your account had an expired subscription. 

## Build 55

- Potentially corrected rotation behaviour for iPads. 

## Build 54

- Fixed an issue where the unread/today counts would change when reading an article from a feed you're not subscribed to.

- Fixed an issue where the selected feed would remain selected after opening recommendations. 

- If you have a URL copied, the app will automatically detect it when attempting to add a new feed. 

- The sidebar items are now correctly highlighted. They no longer use the tint colour when selected. 

- Search in the sidebar now uses Alpha sorting like the rest of the view. 

- Multiple improvements throughout the app for Voice Control (VC) and Voice Over (VO) a11y options.   
    - The app now correctly shows titles for icon only buttons when VC is activated. 
    - The app now correctly updates states for icon only buttons when VC is activated. 
    - Simplified Article labels for VC to make it easier to select articles. They will now be presented as "Article 1", "Article 2" and so on... Previously, the article title's was used which could be difficult to command with long titles. 
    - VO will now read the article index followed by its title. 

## Build 53

- Improves formatting for CJK Text. CJK text should no longer appear as one big blob of text. It may still happen if the source provides it that way. 

- Fixes an issue with the Unreads widget not updating in a timely manner. 

- Unreads Widget intents now work as expected. Added additional option for loading cover images. 

## Build 52

- Use standard path for DB. Using shared container crashes the app in the background. 

## Build 51

- The article viewer will now draw horizontal rules. 

- The app now saves restoration data properly so launching the app from a saved state is now faster.

- Fixes an issue where images in the article viewer would fail to load (network issues, invalid URL or for whatever other reason) and would show a large placeholder image. 

## Build 50

- During first launch, if your account already has a subscription, the trial interface is no longer shown. You are directly taken to the app. 

- Twitter apps selection now works again when tapping tweets.

- Matched the keyboard navigation to the macOS App. 

## Build 49

- Added support for dragging and dropping articles into the Unread or Bookmark rows in the Sidebar to perform respective actions. 

- Added support for dragging feeds to external applications. This action will drag with the RSS Feed URL.

## Build 47

- Updated images for GIF loading and playback controls.

- Tapping a gallery image now opens it in full view.

- Images in Widgets should now load reliably. I've discarded the older method of loading images in favour of a more standard approach as recommended by Apple Engineering. 

## Build 45

### Fixes

- Fixed the app using a semi-bold font for headings on iOS 14.0.1 and higher. 

- Image Loading options now correctly apply to favicons inside the Articles List Interface. 

- Title Font preference now correctly applies to headings inside the article as well. 
