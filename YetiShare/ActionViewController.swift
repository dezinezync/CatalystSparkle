//
//  ActionViewController.swift
//  YetiShare
//
//  Created by Nikhil Nigade on 26/02/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import UIKit
import FeedsLib
import MobileCoreServices

class ActionViewController: UIViewController {
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var activityLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    lazy var DS: UITableViewDiffableDataSource<Int, FeedRecommendation> = {
        
        let ds = UITableViewDiffableDataSource<Int, FeedRecommendation>(tableView: tableView) { (tableView, indexPath, object) -> UITableViewCell? in
            
            let cell = tableView.dequeueReusableCell(withIdentifier: NewFeedResultCell.identifer, for: indexPath) as! NewFeedResultCell
            
            cell.configure(object)
            
            return cell
            
        }
        
        return ds
        
    }()
    
    var selected: IndexPath?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        title = "Add to Elytra"
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 51
        tableView.rowHeight = UITableView.automaticDimension
        
        NewFeedResultCell.register(tableView)
        
        setupData(nil)
        
        checkForInputItems()
        
    }
    
    //MARK: - Internal
    
    func showError(error: Error) {
        
        let avc = UIAlertController.init(title: "An Error Occurred", message: error.localizedDescription, preferredStyle: .alert)
        
        let cancel = UIAlertAction.init(title: "Okay", style: .cancel, handler: nil)
        
        avc.addAction(cancel)
        
        self.present(avc, animated: true, completion: nil)
        
    }
    
    private func checkForInputItems() {
        
        guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            return
        }
        
        activityLabel.text = "Checking for RSS Feed links..."
        activityIndicator.startAnimating()
        
        var foundItems = false
        
        for item in inputItems {
            
            if let attachments = item.attachments, attachments.count > 0 {
                
                for itemProvider in attachments {
                    
                    let plistType = (kUTTypePropertyList as String)
                    let urlType = (kUTTypeURL as String)
                    let textType = (kUTTypeText as String)
                    
                    if itemProvider.hasItemConformingToTypeIdentifier(plistType) {
                        
                        foundItems = true
                        
                        itemProvider.loadItem(forTypeIdentifier: plistType, options: nil) { [unowned self] (data: NSSecureCoding?, error: Error?) in
                            
                            if let error = error {
                             
                                return self.showError(error: error)
                                
                            }
                            
                            guard let responseObject = data as? [String: Any] else {
                                return
                            }
                            
                            if let results = responseObject[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: Any] {
                                
                                if let items = results["items"] as? [[String: Any]] {
                                    
                                    print(items)
                                    
                                    handleInputFeeds(items)
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    else if itemProvider.hasItemConformingToTypeIdentifier(urlType) {
                        
                        itemProvider.loadItem(forTypeIdentifier: urlType, options: nil) { [unowned self] (data, error) in
                            
                            if let error = error {
                                
                                return self.showError(error: error)
                                
                            }
                            
                            if let url = data as? URL {
                                
                                OperationQueue.main.addOperation { [unowned self] in
                                    
                                    self.handleURL(url)
                                    
                                }
                                
                            }
                            
                            foundItems = true
                            
                        }
                        
                    }
                    else if itemProvider.hasItemConformingToTypeIdentifier(textType) {
                        
                        itemProvider.loadItem(forTypeIdentifier: textType, options: nil) { [unowned self] (data, error) in
                            
                            if let error = error {
                                
                                return self.showError(error: error)
                                
                            }
                            
                            if let text = data as? String, let url = URL(string: text) {
                                
                                OperationQueue.main.addOperation { [unowned self] in
                                    
                                    self.handleURL(url)
                                    
                                }
                                
                            }
                            else {
                                
                                let error = NSError(domain: "Elytra", code: 404, userInfo: [NSLocalizedDescriptionKey: "An invalid or no URL was found."])
                                
                                return self.showError(error: error as Error)
                                
                            }
                            
                        }
                        
                        foundItems = true
                        
                    }
                    
                }
                
                if foundItems == true {
                    break
                }
                
            }
            
            if foundItems == true {
                break
            }
            
        }
        
    }
    
    private func handleInputFeeds(_ items: [[String: Any]]) {
        
        if items.count == 0 {
            
            let error = NSError(domain: "Elytra", code: 404, userInfo: [NSLocalizedDescriptionKey: "No RSS Feeds were found on this webpage."])
            return self.showError(error: error as Error)
            
        }
        
        if items.count == 1 {
            
            let feed = items.first!
            
            if let link = feed["url"] as? String, let url = URL(string: link) {
                
                self.finaliseURL(url)
                
            }
            
            return
            
        }
        
        DispatchQueue.main.async {
            
            self.activityIndicator.stopAnimating()
            self.activityIndicator.superview?.isHidden = true
            
        }
        
        let responseItems: [FeedRecommendation] = items.map { (obj) -> FeedRecommendation in
            
            let info = FeedRecommendation()
            info.title = obj["title"] as? String
            info.id = obj["url"] as? String
            
            return info
            
        }
        
        setupData(responseItems)
        
    }
    
    private func setupData(_ items: [FeedRecommendation]?) {
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, FeedRecommendation>()
        snapshot.appendSections([0])
        snapshot.appendItems(items ?? [], toSection: 0)
        
        DS.apply(snapshot)
        
    }
    
    private func handleURL(_ url: URL) {
        
        if url.absoluteString.contains("youtube.com") {
            return self.finaliseURL(url)
        }
        
        activityLabel.text = "Loading..."
        activityIndicator.superview?.isHidden = false
        activityIndicator.startAnimating()
        
        FeedsLib.shared.getFeedInfo(url: url) { [weak self] (error, response: FeedInfoResponse?) in
            
            guard let sself = self else {
                return
            }
            
            if let error = error {
                
                return sself.showError(error: error)
                
            }
            
            guard let response = response else {
                
                let error = NSError(domain: "FeedsLib", code: 500, userInfo: [NSLocalizedDescriptionKey: "No response recevied for this URL."])
                
                return sself.showError(error: error)
                
            }
            
//            response.results
            
        }
        
    }
    
    @objc private func finaliseURL(_ url: URL) {
        
        if Thread.isMainThread == false {
            
            return performSelector(onMainThread: #selector(ActionViewController.finaliseURL(_:)), with: url, waitUntilDone: false)
            
        }
        
        print("Finalising URL \(url)")
        
        guard let selectedURL = URL(string: "yeti://addFeed?URL=\(url.absoluteString)") else {
            return
        }
        
        extensionContext?.completeRequest(returningItems: nil, completionHandler: { (expired) in
            
            // get UIApp thorugh ascii char codes
            guard let className: String = String(data: Data(bytes: [0x55, 0x49, 0x41, 0x70, 0x70, 0x6C, 0x69, 0x63, 0x61, 0x74, 0x69, 0x6F, 0x6E] as [UInt8], count: 13), encoding: .ascii) else {
                return
            }
            
            guard let classI = NSClassFromString(className) as? NSObjectProtocol else {
                return
            }
            
            OperationQueue.main.addOperation {
                
                let selectorName = NSSelectorFromString("sharedApplication")
                
                guard let object = classI.perform(selectorName)?.takeRetainedValue() as? NSObjectProtocol else {
                    return
                }
                
                let openURLSelector = NSSelectorFromString("openURL:")
                
                let _ = object.perform(openURLSelector, with: selectedURL)
                
            }
            
        })
        
    }
    
    //MARK: - Actions
    @IBAction func didTapDone(_ sender: Any) {
        
        guard let selected = selected else {
            
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            
            return
        }
        
        guard let feed = DS.itemIdentifier(for: selected) else {
            
            return
            
        }
        
        if let path = feed.id, let url = URL(string: path) {
            
            finaliseURL(url)
            
        }
        
    }
    
}

extension ActionViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        selected = indexPath
        
    }
    
}
