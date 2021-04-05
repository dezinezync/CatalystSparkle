//
//  FeedPreviewVC.swift
//  Elytra
//
//  Created by Nikhil Nigade on 18/02/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import UIKit
import FeedsLib
import SDWebImage
import Models
import DBManager
import Networking

enum FeedPreviewSection: CaseIterable {
    case none
    case folder
}

class FeedPreviewDatasource : UICollectionViewDiffableDataSource<FeedPreviewSection, Folder> {
    
}

class FeedPreviewVC: UICollectionViewController {
    
    var item: FeedRecommendation!
    var headerRegistration: UICollectionView.SupplementaryRegistration<FeedPreviewHeader>!
    var folderRegistration: UICollectionView.CellRegistration<PreviewFolderCell, Folder>!
    
    weak var selectedFolder: Folder?
    
    static let layout: UICollectionViewCompositionalLayout = {
       
        var layout = UICollectionViewCompositionalLayout { (section: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            var config = UICollectionLayoutListConfiguration(appearance: .sidebarPlain)
            
            if section == 0 {
                
                config.headerMode = .supplementary
                
                return NSCollectionLayoutSection.list(using: config, layoutEnvironment:environment)
            }
            
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment:environment)
            
        }
        
        return layout
        
    }()
    
    lazy var DS: FeedPreviewDatasource = {
       
        var ds = FeedPreviewDatasource(collectionView: collectionView) { [unowned self] (collectionView, indexPath, folder) -> UICollectionViewCell? in
            
            return collectionView.dequeueConfiguredReusableCell(using: self.folderRegistration, for: indexPath, item: folder)
            
        }
        
        ds.supplementaryViewProvider = { [unowned self] (collectionView, elementKind, indexPath) -> UICollectionReusableView? in
            
            if elementKind == UICollectionView.elementKindSectionHeader {
                
                return collectionView.dequeueConfiguredReusableSupplementary(using: self.headerRegistration, for: indexPath)
                
            }
            
            return nil
            
        }
        
        return ds
        
    }()

    override func viewDidLoad() {
        
        super.viewDidLoad()

        title = "New Feed"
        
        setupNavBar()
        setupCollectionView()
        setupData()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .top)
        
    }
    
    // MARK: - Setups
    func setupNavBar() {
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .done, target: self, action: #selector(didTapAdd(sender:)))
        
    }
    
    func setupCollectionView() {
        
        collectionView.backgroundColor = .systemBackground
        
        let headerNib = UINib(nibName: "FeedPreviewHeader", bundle: nil)
        headerRegistration = UICollectionView.SupplementaryRegistration(supplementaryNib: headerNib, elementKind: UICollectionView.elementKindSectionHeader) { [weak self] (header, type, indexPath) in
            
            guard let sself = self else {
                return
            }
            
            if let iconUrl = sself.item.iconUrl {
                
                if let url = URL(string: iconUrl) {
                    
                    header.imageView.sd_setImage(with: url, completed: nil)
                    
                }
                
            }
            
            header.titleLabel.text = sself.item.title
            header.subtitleLabel.text = sself.item.id?.replacingOccurrences(of: "feed/", with: "")
            
        }
        
        folderRegistration = UICollectionView.CellRegistration(handler: { (cell: PreviewFolderCell, indexPath, folder: Folder) in
            
            cell.configure(folder)
            
        })
        
    }
    
    //MARK: - Data
    func setupData () {
        
        var snapshot = NSDiffableDataSourceSnapshot<FeedPreviewSection, Folder>()
        snapshot.appendSections([.none, .folder])
        
        let noneFolder = Folder()
        noneFolder.title = "None"
        noneFolder.folderID = 0
        
        snapshot.appendItems([noneFolder], toSection: FeedPreviewSection.none)
        
        snapshot.appendItems(DBManager.shared.folders, toSection: FeedPreviewSection.folder)
        
        DS.apply(snapshot)
        
    }
    
    //MARK: - Actions
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let folder = DS.itemIdentifier(for: indexPath) else {
            return
        }
        
        if folder.title == "None" || folder.folderID == 0 {
            self.selectedFolder = nil
        }
        else {
            self.selectedFolder = folder
        }
        
    }
    
    @objc func didTapCancel() {
        
        self.navigationController?.dismiss(animated: true, completion: nil)
        
    }
    
    @objc func didTapAdd(sender: UIBarButtonItem?) {
        
        sender?.isEnabled = false
        
        guard let url = URL(string: item.id?.replacingOccurrences(of: "feed/", with: "") ?? "") else {
            sender?.isEnabled = true
            return
        }
        
        coordinator?.addFeed(url: url, folderID: self.selectedFolder?.folderID, completion: { [weak self] result in
            
            guard let sself = self else { return }
            
            switch result {
            case .failure(let error):
                AlertManager.showGenericAlert(withTitle: "An Error Occurred", message: error.localizedDescription, fromVC: sself)
                sender?.isEnabled = true
            case .success(_):
                sself.dismissSelf()
            }
            
        })
        
    }
    
    private func dismissSelf() {
        
        let presenting = presentingViewController
        
        dismiss(animated: true, completion: {
            
            if let presenting = presenting {
                presenting.dismiss(animated: true, completion: nil)
            }
            
        })
        
    }

}
