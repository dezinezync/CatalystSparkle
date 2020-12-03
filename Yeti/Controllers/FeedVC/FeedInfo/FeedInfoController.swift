//
//  FeedInfoController.swift
//  Elytra
//
//  Created by Nikhil Nigade on 02/12/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

import UIKit
import SDWebImage

@objc final class FeedInfoController: UITableViewController {
    
    weak var feed: Feed?
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
        self.feed = feed
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        FeedInfoCell.register(tableView: tableView)
        
        let headerView = self.headerView
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 48 + 24)
        
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = UIView.init()

        self.title = self.feed?.displayTitle
        
        self.modalPresentationStyle = .fullScreen
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "Done", style: .plain, target: self, action: #selector(didTapDone))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if (self.feed?.faviconImage != nil) {
            self.faviconView?.image = self.feed?.faviconImage
        }
        else {
            
            if let proxyPath: String = self.feed?.faviconProxyURI(forSize: 48) {
                
                if let url: URL = URL.init(string: proxyPath) {
                
                    self.faviconView?.sd_setImage(with: url, completed: { (image: UIImage?, error: Error?, _, _) in
                        
                        self.feed?.faviconImage = image
                        
                    })
                    
                }
                
            }
            
        }
        
    }
    
    // MARK: - Actions
    @objc func didTapDone () {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (section == 0) {
            return 3
        }
        else if (section == 1) {
            return 1
        }
        else if (section == 2 && self.feed?.extra.url != nil) {
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
                
                cell.label.text = "Push Notifications"
                cell.toggle.addTarget(self, action: #selector(didTogglePush(toggle:)), for: .valueChanged)
                
                cell.toggle.setOn(self.feed?.isSubscribed ?? false, animated: false)
                
            }
            else if (indexPath.row == 2) {
                
                cell.label.text = "Safari Reader Mode"
                cell.toggle.addTarget(self, action: #selector(didToggleSafariReaderMode(toggle:)), for: .valueChanged)
                
                cell.toggle.setOn(self.feed?.isSubscribed ?? false, animated: false)
                
            }
            
        }
        else if (indexPath.section == 1) {
            
            cell.toggle.isHidden = true
            cell.label.text = self.feed?.url ?? ""
            
        }
        else if (indexPath.section == 2) {
            
            cell.toggle.isHidden = true
            cell.label.text = self.feed?.extra.url ?? ""
            
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if (section == 1) {
            return "Feed URL"
        }
        else if (section == 2 && self.feed?.extra.url != nil) {
            return "Website URL"
        }
        
        return nil
        
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        if (section == 0) {
            let devString = "Toggling Push Notifications or Safari Reader Mode has no effect at the moment. However, these preferences will be saved."
            
            let isRealtime = (self.feed?.isHubSubscribed ?? false) || (self.feed?.rpcCount?.intValue ?? 0) > 2;
            
            let mainString = isRealtime ? "This feed supports real-time notifications." : "Notifications for this feed will be near real-time."
            
            return "\(mainString)\n\n\(devString)"
            
        }
        else {
            return nil
        }
        
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        if (indexPath.section == 1 || (indexPath.section == 2 && self.feed?.extra.url != nil)) {
            
            weak var weakSelf = self
            
            let config = UIContextMenuConfiguration.init(identifier: nil, previewProvider: nil) { _ in
                
                let copy: UIAction = UIAction.init(title: "Copy", image: UIImage.init(systemName: "doc.on.doc"), identifier: nil, discoverabilityTitle: "Copy URL", attributes: .init(), state: .off) { _ in

                    var path: String = ""
                    
                    if (indexPath.section == 1) {
                        path = weakSelf?.feed?.url ?? ""
                    }
                    else if (indexPath.section == 2) {
                        path = weakSelf?.feed?.extra.url ?? ""
                    }
                    
                    if let url = URL.init(string: path) {
                        
                        DispatchQueue.main.async {
                            UIPasteboard.general.url = url
                        }
                        
                    }
                    
                }
                
                let share: UIAction = UIAction.init(title: "Share", image: UIImage.init(systemName: "square.and.arrow.up"), identifier: nil, discoverabilityTitle: "Share URL", attributes: .init(), state: .off) { _ in
                    
                    var path: String = ""
                    
                    if (indexPath.section == 1) {
                        path = weakSelf?.feed?.url ?? ""
                    }
                    else if (indexPath.section == 2) {
                        path = weakSelf?.feed?.extra.url ?? ""
                    }
                    
                    if let url = URL.init(string: path) {
                        
                        DispatchQueue.main.async {
                            let instance = UIActivityViewController.init(activityItems: [url], applicationActivities: nil)
                            weakSelf?.present(instance, animated: true, completion: nil)
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

    // MARK: - Actions
    @objc func didTogglePush(toggle: UISwitch) {
        
        
        
    }
    
    @objc func didToggleSafariReaderMode(toggle: UISwitch) {
        
        
        
    }
    
}
