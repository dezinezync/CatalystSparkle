//
//  FeedInfoController.swift
//  Elytra
//
//  Created by Nikhil Nigade on 02/12/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

import UIKit
import SDWebImage
import DBManager
import Models
import Networking
import Combine

@objc final class FeedInfoController: UITableViewController {
    
    var feed: Feed! {
        didSet {
            if let f = feed {
                let m = DBManager.shared.metadataForFeed(f)
                metadata = m
            }
            else {
                metadata = nil
            }
        }
    }
    
    var metadata: FeedMeta!
    
    weak var faviconView: UIImageView?
    
    var headerView: UIView {
        
        let view: UIView = UIView.init(frame: CGRect.zero)
        view.backgroundColor = .systemGroupedBackground
//        view.heightAnchor.constraint(equalToConstant: 48 + 24).isActive = true
        
        let faviconView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
        faviconView.contentMode = .scaleAspectFit
        faviconView.layer.cornerRadius = 6
        faviconView.layer.cornerCurve = .continuous
        faviconView.clipsToBounds = true
        faviconView.translatesAutoresizingMaskIntoConstraints = false
        
        faviconView.widthAnchor.constraint(equalToConstant: 48).isActive = true
        faviconView.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        view.addSubview(faviconView)
        
        self.faviconView = faviconView
        
        faviconView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        faviconView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        return view
        
    }
    
    @objc public convenience init(feed: Feed) {
        
        let bundle = Bundle.init(for: FeedInfoController.self)
        
        self.init(nibName: "FeedInfoController", bundle: bundle)
        setFeed(feed: feed)
    }
    
    private func setFeed(feed: Feed) {
        self.feed = feed
    }
    
    var folderSub: AnyCancellable?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        FeedInfoCell.register(tableView: tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "folderCell")
        
        let headerView = self.headerView
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 48 + 24)
        
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = UIView.init()

        self.title = self.feed?.displayTitle
        
        self.modalPresentationStyle = .fullScreen
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "Done", style: .plain, target: self, action: #selector(didTapDone))
        
        folderSub = NotificationCenter.default.publisher(for: .feedsUpdated)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                
                let indexPath = IndexPath(row: 0, section: 3)
                guard let cell = self?.tableView.cellForRow(at: indexPath),
                      let sself = self else {
                    return
                }
                
                let folderID = sself.feed.folderID
                
                if folderID == nil || folderID == 0 {
                    cell.textLabel?.text = "None"
                }
                else if let folder = DBManager.shared.folder(for: folderID!) {
                    cell.textLabel?.text = folder.title
                }
                
            })
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if (self.feed?.faviconImage != nil) {
            self.faviconView?.image = self.feed?.faviconImage
        }
        else {
            
            if let proxyURL = self.feed?.faviconProxyURI(size: 48) {
                
                self.faviconView?.sd_setImage(with: proxyURL, completed: { (image: UIImage?, error: Error?, _, _) in
                    
                    self.feed?.faviconImage = image
                    
                })
                
            }
            
        }
        
    }
    
    // MARK: - Actions
    @objc func didTapDone () {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (section == 0) {
            return 3
        }
        else if (section == 1) {
            return 1
        }
        else if (section == 2 && self.feed?.extra?.url != nil) {
            return 1
        }
        else if (section == 3) {
            return 1
        }
        
        return 0
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: FeedInfoCell = tableView.dequeueReusableCell(withIdentifier: kFeedInfoCell, for: indexPath) as! FeedInfoCell

        // Configure the cell...
        
        if (indexPath.section == 0) {
            
            if (indexPath.row == 0) {
                
                cell.toggle.isHidden = true
                cell.label.text = self.feed?.displayTitle
                cell.label.font = UIFont.preferredFont(forTextStyle: .headline)
                
            }
            else if (indexPath.row == 1) {
                
                let realtime = (self.feed?.hubSubscribed == true || ((self.feed?.rpcCount ?? 0) > 2))
                
                cell.label.text = realtime ? "Push Notifications" : "Local Notifications"
                cell.toggle.addTarget(self, action: #selector(didTogglePush(toggle:)), for: .valueChanged)
                
                if (realtime) {
                    
                    // realtime
                    cell.toggle.setOn(self.feed?.subscribed ?? false, animated: false)
                    
                }
                else {
                    
                    // local
                    
                    if let m = metadata {
                        
                        let val = m.localNotifications
                        
                        cell.toggle.setOn(val, animated: false)
                    }
                    
                }
                
            }
            else if (indexPath.row == 2) {
                
                cell.label.text = "Safari Reader Mode"
                cell.toggle.addTarget(self, action: #selector(didToggleSafariReaderMode(toggle:)), for: .valueChanged)
                
                if let m = metadata {
                    
                    let val = m.readerMode
                    
                    cell.toggle.setOn(val, animated: false)
                }
                else {
                    cell.toggle.setOn(false, animated: false)
                }
                
            }
            
        }
        else if (indexPath.section == 1) {
            
            cell.toggle.isHidden = true
            cell.label.text = self.feed?.url.absoluteString ?? ""
            
        }
        else if (indexPath.section == 2) {
            
            cell.toggle.isHidden = true
            cell.label.text = self.feed?.extra?.url?.absoluteString ?? ""
            
        }
        else if (indexPath.section == 3) {

            let fCell = tableView.dequeueReusableCell(withIdentifier: "folderCell", for: indexPath)

            fCell.imageView?.image = UIImage(systemName: "folder")
            
            if let folder = DBManager.shared.folder(for: feed?.folderID ?? 0) {
                
                fCell.textLabel?.text = folder.title
                
            }
            else {
                
                fCell.textLabel?.text = "None"
                
            }
            
            fCell.accessoryType = .disclosureIndicator
            
            return fCell
            
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if (section == 1) {
            return "Feed URL"
        }
        else if (section == 2 && self.feed?.extra?.url != nil) {
            return "Website URL"
        }
        else if (section == 3) {
            return "Folder"
        }
        
        return nil
        
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        if (section == 0) {
            
            let isRealtime = (self.feed?.hubSubscribed ?? false) || (self.feed?.rpcCount ?? 0) > 2;
            
            let mainString = isRealtime ? "This feed supports real-time notifications." : "Notifications for this feed will be near real-time."
            
            return mainString
            
        }
        else {
            return nil
        }
        
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        if (indexPath.section == 1 || (indexPath.section == 2 && self.feed?.extra?.url != nil)) {
            
            let config = UIContextMenuConfiguration.init(identifier: nil, previewProvider: nil) { [weak self] _ in
                
                let copy: UIAction = UIAction.init(title: "Copy", image: UIImage.init(systemName: "doc.on.doc"), identifier: nil, discoverabilityTitle: "Copy URL", attributes: .init(), state: .off) { _ in

                    var url: URL? = nil
                    
                    if (indexPath.section == 1) {
                        url = self?.feed?.url
                    }
                    else if (indexPath.section == 2) {
                        url = self?.feed?.extra?.url
                    }
                    
                    if let url = url {
                        
                        DispatchQueue.main.async {
                            UIPasteboard.general.url = url
                        }
                        
                    }
                    
                }
                
                let share: UIAction = UIAction.init(title: "Share", image: UIImage.init(systemName: "square.and.arrow.up"), identifier: nil, discoverabilityTitle: "Share URL", attributes: .init(), state: .off) { _ in
                    
                    var url: URL? = nil
                    
                    if (indexPath.section == 1) {
                        url = self?.feed?.url
                    }
                    else if (indexPath.section == 2) {
                        url = self?.feed?.extra?.url
                    }
                    
                    if let url = url {
                        
                        DispatchQueue.main.async {
                            let instance = UIActivityViewController.init(activityItems: [url], applicationActivities: nil)
                            self?.present(instance, animated: true, completion: nil)
                        }
                        
                    }
                    
                }
                
                let items: [UIMenuElement] = [copy, share]
                
                let menu = UIMenu.init(title: "URL Actions", image: nil, identifier: nil, options: .init(), children: items)
                
                return menu
                
            }
            
            return config
        }
        
        return nil
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard indexPath.section == 3 && indexPath.row == 0 else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        let vc = FolderInfoVC(style: .insetGrouped)
        vc.coordinator = coordinator
        vc.feed = feed
        
        navigationController?.pushViewController(vc, animated: true)
        
    }

    // MARK: - Actions
    @objc func didTogglePush(toggle: UISwitch) {
        
        guard let feed = self.feed else {
            return
        }
        
        // check which push type the feed supports.
        if (feed.hubSubscribed || ((feed.rpcCount ?? 0) > 2)) {
            
            // supports push
            if (feed.subscribed == true && toggle.isOn == false) {
                
                FeedsManager.shared.unsubscribe(feed) { [weak self] result in
                    
                    guard let sself = self else { return }
                    
                    switch result {
                    case .failure(let error):
                        AlertManager.showGenericAlert(withTitle: "Unsubscribe Failed", message: error.localizedDescription)
                        toggle.setOn(true, animated: true)
                    case .success(let status):
                        if status == true {
                            feed.subscribed = false
                            DBManager.shared.update(feed: feed, metadata: sself.metadata)
                        }
                        else {
                            toggle.setOn(true, animated: true)
                            AlertManager.showGenericAlert(withTitle: "Unsubscribe Failed", message: "An unknown error occurred when unsubscribing.")
                        }
                    }
                    
                }
                
            }
            else if (feed.subscribed == false && toggle.isOn == true) {
                
                FeedsManager.shared.subscribe(feed) { [weak self] result in
                    
                    guard let sself = self else { return }
                    
                    switch result {
                    case .failure(let error):
                        AlertManager.showGenericAlert(withTitle: "Subscribe Failed", message: error.localizedDescription)
                        toggle.setOn(false, animated: true)
                    case .success(let status):
                        if status == true {
                            feed.subscribed = true
                            DBManager.shared.update(feed: feed, metadata: sself.metadata)
                        }
                        else {
                            toggle.setOn(false, animated: true)
                            AlertManager.showGenericAlert(withTitle: "Subscribe Failed", message: "An unknown error occurred when unsubscribing.")
                        }
                    }
                    
                }

            }
            
        }
        else {
            
            // supports local
            
            if let m = metadata {
                
                let val = m.localNotifications
                
                var changed = false
                
                if (val == true && toggle.isOn == false) {
                    
                    m.localNotifications = false
                    changed = true
                    
                }
                else if (val == false && toggle.isOn == true) {
                    
                    m.localNotifications = true
                    changed = true
                    
                }
                
                if (changed) {
                    DBManager.shared.update(feed: feed, metadata: m)
                }
                
            }
            
        }
        
    }
    
    @objc func didToggleSafariReaderMode(toggle: UISwitch) {
        
        guard let feed = self.feed else {
            return
        }
        
        if let m = metadata {
            
            let val = m.readerMode
            
            var changed = false
            
            if (val == true && toggle.isOn == false) {
                
                m.readerMode = false
                changed = true
                
            }
            else if (val == false && toggle.isOn == true) {
                
                m.readerMode = true
                changed = true
                
            }
            
            if (changed) {
                DBManager.shared.update(feed: feed, metadata: m)
            }
            
        }
        
    }
    
}
