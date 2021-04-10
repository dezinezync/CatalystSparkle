//
//  FolderInfoVC.swift
//  Elytra
//
//  Created by Nikhil Nigade on 05/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import UIKit
import DBManager
import Networking
import Models

class FolderInfoVC: UITableViewController {
    
    weak var feed: Feed! {
        didSet {
            if feed != nil {
                selectedID = feed.folderID ?? 0
            }
        }
    }
    
    var selectedID: UInt = 0
    weak var selectedFolder: Folder?
    
    lazy var DS: UITableViewDiffableDataSource<FeedPreviewSection, Folder> = {
        
        let ds = UITableViewDiffableDataSource<FeedPreviewSection, Folder>(tableView: tableView) { [weak self] tv, indexPath, item in
            
            let cell = tv.dequeueReusableCell(withIdentifier: "folderCell", for: indexPath)

            cell.textLabel?.text = item.title
            
            if self?.selectedID == item.folderID {
                cell.accessoryType = .checkmark
            }
            else {
                cell.accessoryType = .none
            }
            
            cell.imageView?.image = UIImage(systemName: "folder")

            return cell
            
        }
        
        return ds
        
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Select a Folder"
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "folderCell")
        
        setupData()
        
    }

    // MARK: - Table view data source
    func setupData() {
        
        var snapshot = NSDiffableDataSourceSnapshot<FeedPreviewSection, Folder>()
        snapshot.appendSections([.none, .folder])
        
        let noneFolder = Folder()
        noneFolder.title = "None"
        noneFolder.folderID = 0
        
        snapshot.appendItems([noneFolder], toSection: FeedPreviewSection.none)
        
        let folders = DBManager.shared.folders.sorted { lhs, rhs in
            return lhs.title.localizedCompare(rhs.title) == .orderedAscending
        }
        
        snapshot.appendItems(folders, toSection: FeedPreviewSection.folder)
        
        DS.apply(snapshot)
        
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let folder = DS.itemIdentifier(for: indexPath) else {
            return
        }
            
        selectedID = folder.folderID
        
        if folder.folderID != 0 {
            selectedFolder = folder
        }
        else {
            selectedFolder = nil
        }
        
        var snapshot = DS.snapshot()
        snapshot.reloadSections([.none, .folder])
        
        DS.apply(snapshot, animatingDifferences: true)
            
        updateStruct()
        
    }
    
    func updateStruct() {
        
        guard feed.folderID == nil else {
            
            if let folder = DBManager.shared.folder(for: feed.folderID!) {
            
                coordinator?.removeFromFolder(feed, folder: folder, completion: { [weak self] result in
                    
                    switch result {
                    case .failure(let error):
                        AlertManager.showGenericAlert(withTitle: "An Error Occurred", message: "An error occurred when removing the feed from its existing feed - \(error.localizedDescription)")
                        
                    case .success(_):
                        self?.updateStruct()
                        
                        NotificationCenter.default.post(name: .feedsUpdated, object: self)
                        
                    }
                    
                })
                
            }
            else {
                feed.folderID = nil
                
                updateStruct()
                
                NotificationCenter.default.post(name: .feedsUpdated, object: self)
                
            }
            
            return
        }
        
        guard selectedID != 0 else {
            navigationController?.popViewController(animated: true)
            return
        }
        
        coordinator?.addToFolder(feed, folder: selectedFolder!, completion: { [weak self] result in
            
            switch result {
            case .failure(let error):
                AlertManager.showGenericAlert(withTitle: "An Error Occurred", message: "An error occurred when adding the feed to the new folder - \(error.localizedDescription)")
                
            case .success(_):
                self?.navigationController?.popViewController(animated: true)
                NotificationCenter.default.post(name: .feedsUpdated, object: self)
            }
            
        })
        
    }

}
