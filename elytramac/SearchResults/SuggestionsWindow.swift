//
//  SuggestionsWindow.swift
//  elytramac
//
//  Created by Nikhil Nigade on 28/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Cocoa

class SuggestionsWindow: NSWindow {
    var parentElement: Any?

    /* Convience initializer that removes the syleMask and backing parameters since they are static values for this class.
     */
    convenience init(contentRect: NSRect, defer flag: Bool) {
        self.init(contentRect: contentRect, styleMask: .borderless, backing: .buffered, defer: true)
    }

    /*  We still need to override the NSWindow designated initializer to properly setup our custom window. This allows us to set the class of a window in IB to SuggestionWindow and still get the correct properties (borderless and transparent).
     */
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        // Regardless of what is passed via the styleMask paramenter, always create a NSBorderlessWindowMask window
        super.init(contentRect: contentRect, styleMask: .borderless, backing: .buffered, defer: flag)

        // This window is always has a shadow and is transparent. Force those setting here.
        hasShadow = true
        backgroundColor = NSColor.clear
        isOpaque = false

    }

    // MARK: -
    // MARK: Accessibility
    /* This window is acting as a popup menu of sorts.  Since this isn't semantically a window, we ignore it for accessibility purposes.  Similarly, the parent of this window is its logical parent in the parent window.  In this code sample, the text field, but essentially any UI element that is the logical 'parent' of the window.
     */
    override func accessibilityIsIgnored() -> Bool {
        return true
    }

    /* If we are asked for our AXParent, return the unignored anscestor of our parent element
     */
    override func accessibilityAttributeValue(_ attribute: NSAccessibility.Attribute) -> Any? {
        if attribute == .parent {
            return (parentElement != nil) ? NSAccessibility.unignoredAncestor(of: parentElement!): nil
        } else {
            return super.accessibilityAttributeValue(attribute)
        }
    }
}
