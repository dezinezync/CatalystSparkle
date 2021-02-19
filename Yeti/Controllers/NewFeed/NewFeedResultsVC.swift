//
//  NewFeedResultsVC.swift
//  Elytra
//
//  Created by Nikhil Nigade on 17/02/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import UIKit
import FeedsLib

class NewFeedResultsVC: UITableViewController {
    
    weak var moveFoldersDelegate: (NSObject & MoveFoldersDelegate)?
    
    var results: RecommendationsResponse? {
        
        didSet {
            setupData()
        }
        
    }
    
    lazy var DS: UITableViewDiffableDataSource<Int, FeedRecommendation> = {
        
        var DS = UITableViewDiffableDataSource<Int, FeedRecommendation>(tableView: tableView) { (tableView, indexPath, item) -> UITableViewCell? in
            
            let cell = tableView.dequeueReusableCell(withIdentifier: NewFeedResultCell.identifer, for: indexPath) as! NewFeedResultCell
            
            cell.configure(item)
            
            return cell
            
        }
        
        return DS
        
    }()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupTableView()
        setupData()
        
    }
    
    func setupTableView() {
        
        tableView.tableFooterView = UIView()
        NewFeedResultCell.register(tableView)
        
        tableView.estimatedRowHeight = 51
        tableView.rowHeight = UITableView.automaticDimension
        
    }
    
    // MARK: - Datasource
    func setupData () {
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, FeedRecommendation>()
        
        snapshot.appendSections([0])
        
        snapshot.appendItems(results?.feedInfos ?? [], toSection: 0)
        
        DS.apply(snapshot, animatingDifferences: tableView.window != nil, completion: nil)
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let item = DS.itemIdentifier(for: indexPath) else {
            return
        }
        
        let instance = FeedPreviewVC(collectionViewLayout: FeedPreviewVC.layout)
        instance.item = item
        instance.moveFoldersDelegate = self.moveFoldersDelegate
        
        let nav = UINavigationController(rootViewController: instance)
        self.present(nav, animated: true, completion: nil)
        
    }
    
}
