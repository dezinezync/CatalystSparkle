//
//  SceneToolbarDelegate.swift
//  Elytra
//
//  Created by Nikhil Nigade on 24/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import Dynamic
import DBManager
import YapDatabase
import Models

#if targetEnvironment(macCatalyst)
extension NSToolbarItem.Identifier  {
    
    static let newItemToolbarIdentifier = NSToolbarItem.Identifier(rawValue:"toolbar.newItem")
    static let appearanceToolbarIdentifier = NSToolbarItem.Identifier(rawValue:"toolbar.appearance")
    static let openInBrowserToolbarIdentifier = NSToolbarItem.Identifier(rawValue:"toolbar.openInBrowser")
    static let openInNewWindowToolbarIdentifier = NSToolbarItem.Identifier(rawValue:"toolbar.openInWindow")
    static let sortingMenuToolbarIdentifier = NSToolbarItem.Identifier(rawValue:"toolbar.sortingMenu")
    static let markItemsMenuToolbarIdentifier = NSToolbarItem.Identifier(rawValue:"toolbar.markItems")
    static let refreshAllToolbarIdentifier = NSToolbarItem.Identifier(rawValue:"toolbar.refreshAll")
    static let shareArticleToolbarIdentifier = NSToolbarItem.Identifier(rawValue:"toolbar.shareArticle")
    static let searchToolbarIdentifier = NSToolbarItem.Identifier(rawValue: "toolbar.search")
    
}

enum SceneType {
    case main
    case article
}

class SceneToolbarDelegate: NSObject, NSToolbarDelegate {
    
    weak var scene: UIWindowScene!
    let sceneType: SceneType = .main
    
    weak var searchItem: NSToolbarItem_Catalyst?
    var popover: Dynamic?
    var searchResultsController: NSObject?
    
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
                .shareArticleToolbarIdentifier,
                .searchToolbarIdentifier
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
        else if itemIdentifier == .searchToolbarIdentifier {
            
//            let cls: NSObject.Type = NSClassFromString("NSSearchField") as! NSObject.Type
//            let searchField: NSSearchField_Catalyst = cls.init() as! NSSearchField_Catalyst
//            searchField.delegate =
            
            let item = NSToolbarItem_Catalyst.searchItem(withItemIdentifier: NSToolbarItem.Identifier.searchToolbarIdentifier.rawValue) { [weak self] text in
                
                self?.didSearch(text: text)
                
            }
            
            Dynamic(item!.view).target = self
            Dynamic(item!.view).action = #selector(didSelectSearch(item:))
            
            searchItem = item
            
            return item
            
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
    
    // MARK: - Search
    @objc func didSelectSearch(item: Any?) {
        
        guard let item = item as? NSObject,
              searchItem!.view as! NSObject != item else {
            return
        }
        
        guard let identifier = item.value(forKey: "identifier") as? String,
              let url = URL(string: "elytra://article/\(identifier)") else {
            return
        }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        
    }
    
    func didSearch(text: String?) {
        
        guard let text = text,
              text.count > 0 else {
            
            if let popover = popover {
                if popover.isShown == true {
                    popover.close()
                }
            }
            
            return
        }
        
        if self.popover == nil {
            
            let popover = Dynamic.NSPopover()
            popover.contentViewController = Dynamic.NSViewController()
            popover.contentViewController.view = Dynamic.NSView()
            
            let view = Dynamic(searchItem!).view
            let bounds = view.bounds
            
            popover.showRelativeToRect(bounds, ofView: view, preferredEdge: 1)
            
            self.popover = popover
            
        }
        else if self.popover!.isShown == false {
            
            let view = Dynamic(searchItem!).view
            let bounds = view.bounds
            
            self.popover!.showRelativeToRect(bounds, ofView: view, preferredEdge: 1)
            
        }
        
        updatePopoverResults(text)
        
    }
    
    func updatePopoverResults(_ text: String) {
        
        guard let popover = self.popover else {
            return
        }
        
        var _results: [String] = []
        let searchText = text.lowercased()
        
        if searchResultsController == nil {
            searchResultsController = MyAppDelegate.sharedGlue.searchResultsController(popover.asObject!, field: searchItem!.view!) as! NSObject
        }
        
        let maxSearchResults: Int = 20
        
        let selector = NSSelectorFromString("updateSearchResults:")
              
        DBManager.shared.uiConnection.asyncRead { [weak self] t in
            
            guard let self = self,
                  let txn = t.ext(DBManagerViews.articlesView.rawValue) as? YapDatabaseFilteredViewTransaction else {
                DispatchQueue.main.async { self?.searchResultsController?.perform(selector, with: []) }
                return
            }
            
            let count = txn.numberOfItems(inGroup: GroupNames.articles.rawValue)
            
            txn.enumerateKeysAndMetadata(inGroup: GroupNames.articles.rawValue, range: NSMakeRange(0, Int(count))) { _, _ in
                return true
            } using: { c, k, meta, index, stop in
                
                guard let metadata = meta as? ArticleMeta else {
                    return
                }
                
                let hasAny = (metadata.titleWordCloud ?? []).filter { $0.contains(searchText) }
                
                if hasAny.count > 0 {
                    
                    _results.append(k)
                    if _results.count == maxSearchResults {
                        stop.pointee = true
                    }
                    
                }
                
            }

            
            guard _results.count > 0 else {
                DispatchQueue.main.async { self.searchResultsController?.perform(selector, with: []) }
                return
            }
            
            // grab the items from the list
            let collection: [Article] = _results.compactMap { key in
                return t.object(forKey: key, inCollection: CollectionNames.articles.rawValue) as? Article
            }
            
            // because collection is a compact map, validate its count again.
            guard collection.count > 0 else {
                DispatchQueue.main.async { self.searchResultsController?.perform(selector, with: []) }
                return
            }
            
            let searchResults: [[String?]] = collection.map {
                
                var item = [
                    $0.identifier,
                    nil,
                    $0.title ?? "Untitled",
                    $0.author
                ]
                
                if let feed = t.object(forKey: "\($0.feedID)", inCollection: CollectionNames.feeds.rawValue) as? Feed {
                    item[1] = feed.faviconProxyURI(size: 32)?.absoluteString
                }
                return item
            }
                
            DispatchQueue.main.async { self.searchResultsController?.perform(selector, with: searchResults) }
            
        }
        
    }
    
}

#endif
