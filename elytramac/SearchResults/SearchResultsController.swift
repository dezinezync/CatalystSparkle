//
//  SearchResultsController.swift
//  elytramac
//
//  Created by Nikhil Nigade on 26/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import AppKit
import SDWebImage

let kTrackerKey = "whichImageView"
let rcvCornerRadius: CGFloat = 12

@objcMembers class SearchResultsController: NSWindowController {
    
    public var hostedView: NSView
    
    public unowned var popover: NSPopover!
    public unowned var parentTextField: NSTextField?
    
    private var viewControllers = [NSViewController]()
    private var trackingAreas = [AnyHashable]()
    private var imageOperations: [SDWebImageCombinedOperation] = []
    
    private var localMouseDownEventMonitor: Any?
    private var localMouseUpEventMonitor: Any?
    
    private var needsLayoutUpdate = false
    
    init(popover: NSPopover, field: NSTextField) {
        
        self.popover = popover
        self.parentTextField = field
        self.hostedView = NSView(frame: popover.contentViewController?.view.bounds ?? .zero)
        
        let contentRec = NSRect(x: 0, y: 0, width: 20, height: 20)
        let window = SuggestionsWindow(contentRect: contentRec, defer: true)
        
        super.init(window: window)
        
        // SuggestionsWindow is a transparent window, create RoundedCornersView and set it as the content view to draw a menu like window.
        let contentView = RoundedCornersView(frame: contentRec)
        window.contentView = contentView
        contentView.autoresizesSubviews = false
        needsLayoutUpdate = true
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        self.hostedView = NSView(frame: .zero)
        super.init(coder: coder)
    }
    
    public func cancelSuggestions() {
        
        updateSearchResults(nil)
        
        if let popover = self.popover {
            popover.performClose(self)
        }
        
        if localMouseDownEventMonitor != nil {
            NSEvent.removeMonitor(localMouseDownEventMonitor!)
            localMouseDownEventMonitor = nil
        }
        
        if localMouseUpEventMonitor != nil {
            NSEvent.removeMonitor(localMouseUpEventMonitor!)
            localMouseUpEventMonitor = nil
        }
        
        parentTextField?.stringValue = ""
        parentTextField?.window?.makeFirstResponder(nil)
        
    }
    
    public func setup() {
        
        // setup auto cancellation if the user clicks outside the suggestion window and parent text field. Note: this is a local event monitor and will only catch clicks in windows that belong to this application. We use another technique below to catch clicks in other application windows.
        localMouseDownEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [NSEvent.EventTypeMask.leftMouseDown, NSEvent.EventTypeMask.rightMouseDown, NSEvent.EventTypeMask.otherMouseDown], handler: {(_ event: NSEvent) -> NSEvent? in
            
            let parentWindow = self.popover.contentViewController?.view.window
            
            // If the mouse event is in the suggestion window, then there is nothing to do.
            var event: NSEvent! = event
            
            if event.window != parentWindow {
                /* Clicks in the parent window should either be in the parent text field or dismiss the suggestions window. We want clicks to occur in the parent text field so that the user can move the caret or select the search text.
                 
                 Use hit testing to determine if the click is in the parent text field. Note: when editing an NSTextField, there is a field editor that covers the text field that is performing the actual editing. Therefore, we need to check for the field editor when doing hit testing.
                 */
                let contentView: NSView? = parentWindow?.contentView
                let locationTest: NSPoint? = contentView?.convert(event.locationInWindow, from: nil)
                let hitView: NSView? = contentView?.hitTest(locationTest ?? NSPoint.zero)
                
                if hitView != self.parentTextField || hitView != self.window,
                   self.parentTextField?.window?.contentView?.hitTest(event!.locationInWindow)?.window != self.parentTextField?.window {
                    // Since the click is not in the parent text field, return nil, so the parent window does not try to process it, and cancel the suggestion window.
                    event = nil
                    self.cancelSuggestions()
                }
            }
            
            return event
        })
        
        localMouseUpEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [NSEvent.EventTypeMask.leftMouseUp, NSEvent.EventTypeMask.rightMouseUp, NSEvent.EventTypeMask.otherMouseUp], handler: {(_ event: NSEvent) -> NSEvent? in

            let parentWindow = self.popover.contentViewController?.view.window
            
            // If the mouse event is in the suggestion window, then there is nothing to do.
            var event: NSEvent! = event
            
            if event.window == parentWindow {
                /* Clicks in the parent window should either be in the parent text field or dismiss the suggestions window. We want clicks to occur in the parent text field so that the user can move the caret or select the search text.
                 
                 Use hit testing to determine if the click is in the parent text field. Note: when editing an NSTextField, there is a field editor that covers the text field that is performing the actual editing. Therefore, we need to check for the field editor when doing hit testing.
                 */
                let contentView: NSView? = parentWindow?.contentView
                let hitView: NSView? = contentView?.hitTest(event.locationInWindow)
                
                let requiredView: HighlightingView? = ((hitView is HighlightingView) ? hitView : (hitView?.superview is HighlightingView) ? hitView?.superview : nil) as? HighlightingView
                
                if requiredView == nil {
                    // Since the click is not in the parent text field, return nil, so the parent window does not try to process it, and cancel the suggestion window.
                    event = nil
                    self.cancelSuggestions()
                }
                else {
                    // call our local method
                    self.mouseUp(view: requiredView!)
                }
            }
            
            return event
            
        })
        
    }
    
    public func cleanup() {
        
        // cancel any pending or on-going image operations.
        if imageOperations.count > 0 {
            
            for op in imageOperations {
                op.cancel()
            }
            
            imageOperations = []
            
        }
        
        for viewController in viewControllers {
            viewController.view.removeFromSuperview()
        }
        
        viewControllers.removeAll()
        
        for trackingArea in trackingAreas {
            if let nsTrackingArea = trackingArea as? NSTrackingArea {
                hostedView.removeTrackingArea(nsTrackingArea)
            }
        }
        trackingAreas.removeAll()
        
        for subview in hostedView.subviews {
            subview.removeFromSuperview()
        }
        
        if localMouseDownEventMonitor == nil {
            setup()
        }
        
    }
    
    public func updateSearchResults(_ searchResults: [Any]?) {
        
        cleanup()
        
        let view = hostedView
        
        guard let searchResults = searchResults as? [[String?]],
              searchResults.count > 0 else {
            
            var frame = NSRectFromCGRect(CGRect(x: 0, y: 0, width: 120, height: 24))
            let field = NSTextField(frame: frame)
            field.isEditable = false
            field.isBezeled = false
            field.alignment = .center
            field.backgroundColor = .clear
            field.stringValue = "No Results";
            field.sizeToFit()
            
            view.addSubview(field)
            
            /**
             * Doing this breaks the intrinsic contentSize of the popover.
             *
            NSLayoutConstraint.activate([
                field.widthAnchor.constraint(equalToConstant: field.bounds.size.width),
                field.heightAnchor.constraint(equalToConstant: field.bounds.size.height),
                field.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                field.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
            
            if let window = view.window,
               let popover: NSPopover = window.value(forKey: "_popover") as? NSPopover {

                popover.contentSize = NSSize(width: 240, height: 120)

            }
             */
            frame.size = field.intrinsicContentSize
            
            frame.origin.x = view.frame.midX - (frame.size.width / 2) - 8
            frame.origin.y = view.frame.midY - (frame.size.height / 2)
            
            field.frame = frame
            
            return
        }
        
        let contentView = popover.contentViewController!.view
        
        /* Iterate througn each suggestion creating a view for each entry.
         */
        /* The width of each suggestion view should match the width of the window. The height is determined by the view's height set in IB.
         */
        var contentFrame: NSRect = contentView.frame
        var frame = NSRect(x: 0, y: rcvCornerRadius, width: contentFrame.width, height: 0.0)
        
        // we reverse the order here to show latest first
        let results: [SearchItem] = searchResults.map { SearchItem(identifier:$0[0]!, imagePath: ($0[1] != nil ? URL(string: $0[1]!) : nil), label: $0[2]!, detailLabel: $0[3]) }.reversed()
        
        for entry: SearchItem in results {
            
            frame.origin.y += frame.size.height
            let viewController = NSViewController(nibName: NSNib.Name("SuggestionPrototype"), bundle: Bundle(for: Self.self))
            let view = viewController.view as? HighlightingView
            
//            // Make the selectedView the samee as the 0th.
//            if viewControllers.count == 0 {
//                selectedView = view
//            }
            // Use the height of set in IB of the prototype view as the heigt for the suggestion view.
            frame.size.height = (view?.frame.size.height)!
            view?.frame = frame
            if let aView = view {
                contentView.addSubview(aView)
            }
            
            // don't forget to create the tracking area.
            let trackingArea = self.trackingArea(for: view) as? NSTrackingArea
            if let anArea = trackingArea {
                contentView.window?.contentView?.addTrackingArea(anArea)
            }
            
            // convert the suggestion enty to a mutable dictionary. This dictionary is bound to the view controller's representedObject. The represented object is what all the subviews are bound to in IB. We must use a mutable dictionary because we may change one of its key values.
            let mutableEntry = entry
            viewController.representedObject = mutableEntry
            viewControllers.append(viewController)
            
            if let anArea = trackingArea {
                trackingAreas.append(anArea)
            }
            
            if let imageURL = entry.imagePath {
                
                DispatchQueue.global().async {
                    
                    if let op = SDWebImageManager.shared.loadImage(with: imageURL, options: [.scaleDownLargeImages], progress: nil, completed: { (image, data, error, cacheType, finished, imageURL) in
                        
                        if let image = image {
//                            print("downloaded image for url \(imageURL!), size: \(image.size)")
                            
                            DispatchQueue.main.async {
                                entry.image = image
                                view?.imageView.image = image
                                view?.progressIndicator.stopAnimation(self)
                            }
                        }
                        
                    }) {
                    
                        self.imageOperations.append(op)
                        
                    }
                    
                }
                
            }
            
        }
        
        /* We have added all of the suggestion to the window. Now set the size of the window.
         */
        // Don't forget to account for the extra room needed the rounded corners.
        contentFrame.size.height = frame.maxY + rcvCornerRadius
        var winFrame: NSRect = NSRect(origin: window!.frame.origin, size: window!.frame.size)
        winFrame.origin.y = winFrame.maxY - contentFrame.height
        winFrame.size.height = contentFrame.height
        window?.setFrame(winFrame, display: true)
        
        var size = self.popover.contentSize
        size.height = winFrame.size.height
        
        self.popover.contentSize = size
        
    }
    
    /* Custom selectedView property setter so that we can set the highlighted property of the old and new selected views.
     */
    private var selectedView: NSView? {
        didSet {
            if selectedView != oldValue {
                (oldValue as? HighlightingView)?.setHighlighted(false)
            }
            (selectedView as? HighlightingView)?.setHighlighted(true)
        }
    }
    
    // MARK: -
    // MARK: Mouse Tracking
    /* Mouse tracking is easily accomplished via tracking areas. We setup a tracking area for suggestion view and watch as the mouse moves in and out of those tracking areas.
     */
    /* Properly creates a tracking area for an image view.
     */
    func trackingArea(for view: NSView?) -> Any? {
        
        // make tracking data (to be stored in NSTrackingArea's userInfo) so we can later determine the imageView without hit testing
        var trackerData: [AnyHashable: Any]? = nil
        
        if let aView = view {
            trackerData = [
                kTrackerKey: aView
            ]
        }
        
        let trackingRect: NSRect = view!.superview!.convert(view?.bounds ?? CGRect.zero, from: view)
        let trackingOptions: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInActiveApp]//[.enabledDuringMouseDrag, .mouseEnteredAndExited, .activeInActiveApp]
        let trackingArea = NSTrackingArea(rect: trackingRect, options: trackingOptions, owner: self, userInfo: trackerData)
        return trackingArea
    }
    
    /* Set selected view and send action
     */
    func userSetSelectedView(_ view: NSView?) {
        selectedView = view
//        NSApp.sendAction(action!, to: target, from: self)
    }
    
    /* The mouse is now over one of our child image views. Update selection and send action.
     */
    override func mouseEntered(with event: NSEvent) {
        let view: NSView?
        if let userData = event.trackingArea?.userInfo as? [String: NSView] {
            view = userData[kTrackerKey]!
        } else {
            view = nil
        }
        userSetSelectedView(view)
        super.mouseEntered(with: event)
    }

    /* The mouse has left one of our child image views. Set the selection to no selection and send action
     */
    override func mouseExited(with event: NSEvent) {
        userSetSelectedView(nil)
        super.mouseExited(with: event)
    }

    /* The user released the mouse button. Force the parent text field to send its return action. Notice that there is no mouseDown: implementation. That is because the user may hold the mouse down and drag into another view.
     */
    func mouseUp(view: HighlightingView) {
        
        parentTextField?.validateEditing()
        parentTextField?.abortEditing()
        
        let controllers = viewControllers.filter { $0.view == view }
        
        // get the item from the view controller's representedObject
        if let viewController = viewControllers.first(where: { $0.view == view }),
           let target = parentTextField?.target,
           let action = parentTextField?.action {
            
            let _ = target.perform(action, with: viewController.representedObject)
            
        }
            
        cancelSuggestions()
    }

    // MARK: -
    // MARK: Keyboard Tracking
    /* In addition to tracking the mouse, we want to allow changing our selection via the keyboard. However, the suggestion window never gets key focus as the key focus remains on te text field. Therefore we need to route move up and move down action commands from the text field and this controller. See CustomMenuAppDelegate.m -control:textView:doCommandBySelector: to see how that is done.
     */
    /* move the selection up and send action.
     */
    override func moveUp(_ sender: Any?) {
        let selectedView: NSView? = self.selectedView
        var previousView: NSView? = nil
        for viewController: NSViewController in viewControllers {
            let view: NSView? = viewController.view
            if view == selectedView {
                break
            }
            previousView = view
        }
        if previousView != nil {
            userSetSelectedView(previousView)
        }
    }
    /* move the selection down and send action.
     */
    override func moveDown(_ sender: Any?) {
        let selectedView: NSView? = self.selectedView
        var previousView: NSView? = nil
        for viewController: NSViewController in viewControllers.reversed() {
            let view: NSView? = viewController.view
            if view == selectedView {
                break
            }
            previousView = view
        }
        if previousView != nil {
            userSetSelectedView(previousView)
        }
    }
}
