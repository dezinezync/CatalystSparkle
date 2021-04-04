//
//  AppDelegate+Routing.swift
//  Elytra
//
//  Created by Nikhil Nigade on 02/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import JLRoutes
import Defaults
import DBManager
import Models
import Networking
import SafariServices

extension AppDelegate {
    
    @objc func setupRouting() {
        
        JLRoutes(forScheme: "feed").addRoute("*") { [weak self] params in
            
            self?.popToRoot()
            
            guard let url: URL = params[JLRouteURLKey] as? URL else {
                return false
            }
            
            let base: String = url.absoluteString.replacingOccurrences(of: "feed:", with: "")
            
            if let feedURL = URL(string: base) {
                self?.addFeed(url: feedURL)
                return true
            }
            
            return false
            
        }
        
        JLRoutes.global().addRoute("/addFeedConfirm") { [weak self] params in
            
            guard let path: String = params["URL"] as? String else {
                return true
            }
            
            guard let url = URL(string: path) else {
                AlertManager.showGenericAlert(withTitle: "Invalid URL", message: "The URL seems to be invalid or Elytra was unable to process it correctly.")
                return true
            }
            
            runOnMainQueueWithoutDeadlocking {
                
                let avc = UIAlertController(title: "Add Feed?", message: path, preferredStyle: .alert)
                
                avc.addAction(UIAlertAction(title: "Add", style: .default, handler: { _ in
                    
                    self?.addFeed(url: url)
                    
                }))
                
                avc.addAction(UIAlertAction(title: "Open in Browser", style: .default, handler: { _ in
                    
                    self?.openURL(url: url)
                    
                }))
                
                avc.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                self?.coordinator.splitVC.present(avc, animated: true, completion: nil)
                
            }
            
            return true
            
        }
        
        JLRoutes.global().addRoute("/addFeed") { [weak self] params in
            
            self?.popToRoot()
            
            if let path: String = params["URL"] as? String {
                
                guard let url = URL(string: path) else {
                    AlertManager.showGenericAlert(withTitle: "Invalid URL", message: "The URL seems to be invalid or Elytra was unable to process it correctly.")
                    return true
                }
                
                self?.addFeed(url: url)
                
            }
            else if let feedID: Int = params["feedID"] as? Int {
                
                self?.addFeed(id: UInt(feedID))
                
            }
            
            return true
            
        }
        
        JLRoutes.global().addRoute("/twitter/:type/identifier") { [weak self] params in
            
            if let type = params["type"] as? String,
               let identifier = params["identifier"] as? String {
                
                if type == "user" || type == "user_mention" {
                    self?.openTwitterUser(identifier)
                }
                else if type == "status" {
                    self?.openTwitterStatus(identifier)
                }
                
            }
            
            return true
            
        }
        
        JLRoutes.global().addRoute("/feed/:feedID") { [weak self] params in
            
            if let fID = params["feedID"] as? String {
                
                let feedID = (fID as NSString).integerValue
                
                self?.openFeed(id: UInt(feedID))
                
            }
            
            return true
            
        }
        
        JLRoutes.global().addRoute("/feed/:feedID/article/:articleID") { [weak self] params in
            
            if let fID = params["feedID"] as? String,
               let article = params["articleID"] as? String {
                
                let feedID = (fID as NSString).integerValue
                
                self?.openFeed(id: UInt(feedID), article: article)
                
            }
            
            return true
            
        }
        
        JLRoutes.global().addRoute("/article/:articleID") { [weak self] params in
            
            if let article = params["articleID"] as? String {
                
                self?.openArticle(article)
                
            }
            
            return true
            
        }
        
        JLRoutes.global().addRoute("/external") { [weak self] params in
            
            if let baseURL: URL = params[JLRouteURLKey] as? URL {
                
                var path = baseURL.absoluteString.replacingOccurrences(of: "yeti://external?link=", with: "")
                
                #if targetEnvironment(macCatalyst)
                /*
                 * Clicking shift when opening the article
                 * will reverse the background action
                 */
                var openInBackground = Defaults[.browserOpenInBackground]
                
                if let shiftClickedVal = params["shift"] as? Bool,
                   shiftClickedVal == true {
                    
                    openInBackground = !openInBackground
                    
                }
                
                if path.contains("&shift=1") {
                    path = path.replacingOccurrences(of: "&shift=1", with: "")
                }
                
                if let url = URL(string: path) {
                    // @TODO
                    self?.sharedGlue.open(url, inBackground: openInBackground)
                    
                }
                
                #else
                
                // check and optionally handle Twitter URLs
                if path.contains("twitter.com") {
                    
                    if let exp = try? NSRegularExpression(pattern: "https?\\:\\/\\/w{0,3}\\.?twitter.com\\/([a-zA-Z0-9]*)$", options: .caseInsensitive) {
                        
                        let matches = exp.matches(in: path, options: [], range: NSMakeRange(0, path.count))
                        
                        if matches.count > 0 {
                            
                            let username = (path as NSString).lastPathComponent
                            
                            self?.openTwitterUser(username)
                            
                            return true
                            
                        }
                        
                    }
                    
                    if let exp = try? NSRegularExpression(pattern: "https?\\:\\/\\/w{0,3}\\.?twitter.com\\/([a-zA-Z0-9]*)\\/status\\/([0-9]*)$", options: .caseInsensitive) {
                        
                        let matches = exp.matches(in: path, options: [], range: NSMakeRange(0, path.count))
                        
                        if matches.count > 0 {
                            
                            let identifier = (path as NSString).lastPathComponent
                            
                            self?.openTwitterStatus(identifier)
                            
                            return true
                            
                        }
                        
                    }
                    
                }
                
                if path.contains("reddit.com") {
                    
                    let client = Defaults[.externalRedditApp]
                    
                    // Reference: https://www.reddit.com/r/redditmobile/comments/526ede/ios_url_schemes_for_ios_app/
                    
                    if var comps = URLComponents(string: path) {
                        comps.scheme = client.lowercased()
                        comps.host = ""
                        
                        if client == "Narwhal" {
                            
                            let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
                            
                            comps.path = "/open-url/\(encoded!)"
                            
                        }
                        
                        if let url = comps.url {
                            
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            
                        }
                        
                        return true
                        
                    }
                    
                }
                
                self?.openURL(url: baseURL)
                
                #endif
                
            }
            
            return true
            
        }
        
    }
    
    // MARK: - Helpers
    func popToRoot() {
        
        guard let splitVC = coordinator.splitVC else {
            return
        }
        
        guard let nav = splitVC.viewController(for: .primary) as? UINavigationController else {
            return
        }
        
        nav.popToRootViewController(animated: false)
        
    }
    
    func addFeed(url: URL) {
        
        popToRoot()
        
        coordinator.addFeed(url: url)
        
    }
    
    func addFeed(id: UInt) {
        
        popToRoot()
        
        coordinator.addFeed(id: id)
        
    }
    
    func openFeed(id: UInt) {
        openFeed(id: id, article: nil)
    }
    
    func openFeed(id: UInt, article: String?) {
        
        if coordinator.splitVC.traitCollection.userInterfaceIdiom == .phone {
            popToRoot()
        }
        
        if coordinator.feedVC != nil {
            
            // check if it's the same Feed
            if coordinator.feedVC!.type == .natural,
               coordinator.feedVC!.feed!.feedID == id {
                
                // same.
                if (article != nil) {
                    openArticle(article!)
                }
                
                return
                
            }
            
            guard let feed = DBManager.shared.feedForID(id) else {
                AlertManager.showGenericAlert(withTitle: "Invalid Feed", message: "This feed does not exist in your list.")
                return
            }
            
            coordinator.showFeedVC(feed)
            
        }
        
        if article != nil {
            openArticle(article!)
        }
        
    }
    
    func openArticle(_ articleID: String) {
        
        if coordinator.articleVC != nil {
            
            // check the article
            if let article = coordinator.articleVC!.item as? Article,
               article.identifier == articleID {
                // same article
                return
            }
            
        }
        
        let article = Article()
        article.identifier = articleID
        
        coordinator.showArticle(article)
        
    }
    
    func openTwitterUser(_ username: String) {
        
        let scheme: String = Defaults[.externalTwitterApp].lowercased()
        var url: URL!
        
        if scheme == "twitter" {
            url = URL(string: "\(scheme)://user?screen_name=\(username)")
        }
        else if scheme == "tweetbot" {
            url = URL(string: "\(scheme)://dummyname/user_profile/\(username)")
        }
        else if scheme == "twitterrific" {
            url = URL(string: "\(scheme)://current/profile?screen_name=\(username)")
        }
        
        guard url != nil else {
            return
        }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        
    }
    
    func openTwitterStatus(_ identifier: String) {
        
        let scheme: String = Defaults[.externalTwitterApp].lowercased()
        var url: URL!
        
        if scheme == "twitter" {
            url = URL(string: "\(scheme)://status?id=\(identifier)")
        }
        else if scheme == "tweetbot" {
            url = URL(string: "\(scheme)://dummyname/status/\(identifier)")
        }
        else if scheme == "twitterrific" {
            url = URL(string: "\(scheme)://current/tweet?id=\(identifier)")
        }
        
        guard url != nil else {
            return
        }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        
    }
    
    func openURL(url: URL) {
        
        let scheme: String = Defaults[.externalBrowserApp].lowercased()
        
        var uri: String = url.absoluteString.replacingOccurrences(of: "yeti://external?link=", with: "")
        
        var finalURL: URL!
        
        if scheme == "chrome" {
            
            if uri.contains("https:") {
                finalURL = URL(string: "googlechromes://\(uri.replacingOccurrences(of: "https://", with: ""))")
            }
            else {
                finalURL = URL(string: "googlechrome://\(uri.replacingOccurrences(of: "http://", with: ""))")
            }
            
        }
        else if scheme == "firefox" {
            finalURL = URL(string: "firefox://open-url?url=\(uri)")
        }
        else if scheme == "safari" {
            
            let config: SFSafariViewController.Configuration = SFSafariViewController.Configuration()
            
            if uri.contains("&ytreader=1") {
                
                uri = uri.replacingOccurrences(of: "&ytreader=1", with: "")
                
                config.entersReaderIfAvailable = true
                
            }
            
            finalURL = URL(string: uri)
            
            let sfvc = SFSafariViewController(url: finalURL, configuration: config)
            sfvc.preferredControlTintColor = SharedPrefs.tintColor
            
            var navVC: UINavigationController!
            
            if coordinator.splitVC.traitCollection.userInterfaceIdiom == .pad,
               coordinator.splitVC.traitCollection.horizontalSizeClass == .regular {
                navVC = coordinator.splitVC.viewControllers.last as? UINavigationController
            }
            else {
                navVC = coordinator.splitVC.viewControllers.first as? UINavigationController
            }
            
            if navVC != nil {
                navVC!.present(sfvc, animated: true, completion: nil)
            }
            
            return
            
        }
        
        guard finalURL != nil else {
            return
        }
        
        UIApplication.shared.open(finalURL, options: [:], completionHandler: nil)
        
    }
    
}
