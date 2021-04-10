//
//  NewFeedResultsVC.swift
//  Elytra
//
//  Created by Nikhil Nigade on 17/02/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import UIKit
import FeedsLib
import Models

class NewFeedResultsVC: UITableViewController {
    
    var isLoading: Bool = false {
        didSet {
            
            UIView.animate(withDuration: 0.2, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) { [weak self] in
                
                if (self?.isLoading == true) {
                    
                    if self?.activityIndicator.isHidden == true {
                        self?.activityIndicator.isHidden = false
                    }
                    
                    self?.activityIndicator.startAnimating()
                    
                }
                else {
                    self?.activityIndicator.stopAnimating()
                }
                
            } completion: { (_) in }

        }
    }
    
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
    
    let activityIndicator: UIActivityIndicatorView = {
       
        let ai = UIActivityIndicatorView(style: .large)
        ai.sizeToFit()
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            ai.widthAnchor.constraint(equalToConstant: ai.bounds.size.width),
            ai.heightAnchor.constraint(equalToConstant: ai.bounds.size.height)
        ])
        
        return ai
        
    }()
    
    var didSetupActivityConstraints: Bool = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupTableView()
        setupData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if didSetupActivityConstraints == false {
            
            didSetupActivityConstraints = true
            
            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor, constant: -44)
            ])
            
        }
        
    }
    
    func setupTableView() {
        
        tableView.tableFooterView = UIView()
        NewFeedResultCell.register(tableView)
        
        tableView.estimatedRowHeight = 51
        tableView.rowHeight = UITableView.automaticDimension
        
        tableView.addSubview(activityIndicator)
        
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
        instance.coordinator = self.coordinator
        
        let nav = UINavigationController(rootViewController: instance)
        self.present(nav, animated: true, completion: nil)
        
    }
    
}
