//
//  SceneToolbarDelegate.swift
//  Elytra
//
//  Created by Nikhil Nigade on 24/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation

extension NSToolbarItem.Identifier  {
    
    static let newItemToolbarIdentifier = NSToolbarItem.Identifier(rawValue:"toolbar.newItem")
    static let appearanceToolbarIdentifier = NSToolbarItem.Identifier(rawValue:"toolbar.appearance")
    static let openInBrowserToolbarIdentifier = NSToolbarItem.Identifier(rawValue:"toolbar.openInBrowser")
    static let openInNewWindowToolbarIdentifier = NSToolbarItem.Identifier(rawValue:"toolbar.openInWindow")
    static let sortingMenuToolbarIdentifier = NSToolbarItem.Identifier(rawValue:"toolbar.sortingMenu")
    static let markItemsMenuToolbarIdentifier = NSToolbarItem.Identifier(rawValue:"toolbar.markItems")
    static let refreshAllToolbarIdentifier = NSToolbarItem.Identifier(rawValue:"toolbar.refreshAll")
    static let shareArticleToolbarIdentifier = NSToolbarItem.Identifier(rawValue:"toolbar.shareArticle")
    
}

enum SceneType {
    case main
    case article
}

class SceneToolbarDelegate: NSObject, NSToolbarDelegate {
    
    weak var scene: UIWindowScene!
    let sceneType: SceneType = .main
    
    init(scene: UIWindowScene) {
        self.scene = scene
    }
    
    // MARK: - Delegate
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        
        if sceneType == .main {
            
            return [
                .flexibleSpace,
                .newItemToolbarIdentifier,
                .primarySidebarTrackingSeparatorItemIdentifier,
                .flexibleSpace,
                .refreshAllToolbarIdentifier,
                .sortingMenuToolbarIdentifier,
                .markItemsMenuToolbarIdentifier,
                .supplementarySidebarTrackingSeparatorItemIdentifier,
                .flexibleSpace,
                .openInNewWindowToolbarIdentifier,
                .openInBrowserToolbarIdentifier,
                .appearanceToolbarIdentifier,
                .shareArticleToolbarIdentifier
            ]
            
        }
        
        return []
        
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        
        return toolbarDefaultItemIdentifiers(toolbar)
        
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {

        let coordinator: Coordinator = MyAppDelegate.coordinator
        
        if itemIdentifier == .newItemToolbarIdentifier {
            
            let newFeedAction = UIAction(title: "New Feed", image: UIImage(systemName: "plus"), identifier: nil) { _ in
                
                coordinator.showNewFeedVC()
                
            }
            
            let newFolderAction = UIAction(title: "New Folder", image: UIImage(systemName: "folder.badge.plus"), identifier: nil) { _ in
                
                coordinator.showNewFolderVC()
                
            }
            
            let menu = UIMenu(children: [newFeedAction, newFolderAction])
            
            let item = NSMenuToolbarItem(itemIdentifier: itemIdentifier)
            item.showsIndicator = true
            item.itemMenu = menu
            item.image = UIImage(systemName: "plus")
            
            return item
        }
        else if itemIdentifier == .openInNewWindowToolbarIdentifier {
            
            return toolbarItem(itemIdentifier, title: "Open in New Window", buttonImageName: "macwindow.on.rectangle", target: nil, selector: NSSelectorFromString("openArticleInNewWindow"))
            
        }
        else if itemIdentifier == .refreshAllToolbarIdentifier {
            
            return toolbarItem(itemIdentifier, title: "Refresh Feeds", buttonImageName: "bolt.circle", target: nil, selector: NSSelectorFromString("beginRefreshingAll:"))
            
        }
        else if itemIdentifier == .shareArticleToolbarIdentifier {
            
            return toolbarItem(itemIdentifier, title: "Share Article", buttonImageName: "square.and.arrow.up", target: nil, selector: NSSelectorFromString("didTapShare:"))
            
        }
        else if itemIdentifier == .appearanceToolbarIdentifier {
            
            return toolbarItem(itemIdentifier, title: "Appearance", buttonImageName: "doc.richtext", target: nil, selector: NSSelectorFromString("didTapCustomize:"))
            
        }
        else if itemIdentifier == .openInBrowserToolbarIdentifier {
            
            return toolbarItem(itemIdentifier, title: "Open In Browser", buttonImageName: "safari", target: nil, selector: NSSelectorFromString("openInBrowser"))
            
        }
        else if itemIdentifier == .sortingMenuToolbarIdentifier {
            
            let item = SortingMenuToolbarItem(itemIdentifier: itemIdentifier)
            (scene.delegate as? SceneDelegate)?.sortingItem = item
            
            return item
            
        }
        else if itemIdentifier == .markItemsMenuToolbarIdentifier {
            
            return toolbarItem(itemIdentifier, title: "Mark All Read", buttonImageName: "checkmark", target: nil, selector: NSSelectorFromString("didTapMarkAll:"))
            
        }
        else {
            fatalError("Item should be non-nil")
            return nil
        }

    }
    
    func toolbarItem(_ identifier: NSToolbarItem.Identifier, title: String?, buttonImageName: String?, target: Any?, selector: Selector?) -> NSToolbarItem {
        
        var button: UIBarButtonItem?
        
        if let buttonImageName = buttonImageName,
           let sel = selector {
            
            let image = UIImage(systemName: buttonImageName)
            
            button = UIBarButtonItem(image: image, style: .plain, target: target, action: sel)
            
        }
        
        var item: NSToolbarItem
        
        if let button = button {
            
            item = NSToolbarItem(itemIdentifier: identifier, barButtonItem: button)
            
            item.label = ""
            
        }
        else {
            item = NSToolbarItem(itemIdentifier: identifier)
            item.label = title ?? "No Title"
        }
        
        if let title = title {
            item.paletteLabel = title
            item.toolTip = title
        }
             
        return item
        
    }
    
}
