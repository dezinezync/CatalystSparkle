//
//  NewFeedVC.swift
//  Elytra
//
//  Created by Nikhil Nigade on 17/02/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import FeedsLib

private let recommendationTopics = [
    "News",
    "Tech",
    "Science",
    "Food",
    "Photography",
    "Sports",
    "Entertainment",
    "Movies",
    "Business",
    "Finance",
    "Health",
    "Travel",
    "Fashion",
    "Design"
]

@objc class NewFeedVC: UICollectionViewController {
    
    @objc public static let gridLayout: UICollectionViewCompositionalLayout = {
        
        let layout = UICollectionViewCompositionalLayout { (sectionNumber, env) -> NSCollectionLayoutSection? in
            
            let itemFraction: CGFloat = env.traitCollection.userInterfaceIdiom == .pad ? 0.33 : 0.5
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(itemFraction), heightDimension: .absolute(120))

            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(120))

            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets.leading = 12
            section.contentInsets.trailing = 12

            return section
                
        }
        
        return layout
        
    }()
    
    lazy var searchController: UISearchController = {
       
        var sc = UISearchController(searchResultsController: NewFeedResultsVC(style: .plain))
        sc.searchResultsUpdater = self
//        sc.delegate = self
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder = "#topic or Website URL"
        sc.searchBar.accessibilityHint = sc.searchBar.placeholder
        
        return sc
        
    }()
    
    private var isLoading: Bool = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        title = "New Feed"
        
        setupCollectionView()
        setupNavBar()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - Setups
    func setupCollectionView() {
        
        collectionView.backgroundColor = .systemBackground
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        
        NewFeedReccomendationCell.register(collectionView)
        
    }
    
    func setupNavBar() {
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.largeTitleDisplayMode = .automatic
        navigationItem.searchController = searchController
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancel))
        
    }
    
    // MARK: - Actions
    @objc func didTapCancel () {
        
        navigationController?.dismiss(animated: true, completion: nil)
        
    }
    
}

// MARK: - Collection View Datasource

extension NewFeedVC {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recommendationTopics.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewFeedReccomendationCell.identifier, for: indexPath) as! NewFeedReccomendationCell
        
        cell.titleLabel.text = recommendationTopics[indexPath.item]
        
        cell.setNeedsLayout()
        
        return cell
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let topic = recommendationTopics[indexPath.item]
        
        searchController.searchBar.text = "#\(topic)"
        searchController.searchBar.becomeFirstResponder()
        
    }
    
}

extension NewFeedVC: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        guard isLoading == false else {
            return
        }
        
        guard let text = searchController.searchBar.text else {
            return
        }
        
        guard let resultsInstance = self.searchController.searchResultsController as? NewFeedResultsVC else {
            return
        }
        
        var stripped: String
        
        if text.isEmpty == true {
            resultsInstance.results = nil
            return
        }
        
        if text.count < 2 {
            resultsInstance.results = nil
            return
        }
        
        if text.contains("#") == true {
            
            stripped = (text as NSString).substring(from: 1)
            
            if stripped.count < 2 {
                return
            }
            
        }
        else {
            stripped = text
        }
        
        let locale = Locale.current.languageCode ?? "en"
        
        isLoading = true
        
        FeedsLib.shared.getRecommendations(topic: stripped.lowercased(), locale: locale) { [weak self] (error: Error?, response: RecommendationsResponse?) in
            
            guard let sself = self else {
                return
            }
         
            sself.isLoading = false
            
            guard error == nil else {
                
                resultsInstance.results = nil
                
                AlertManager.showGenericAlert(withTitle: "Error Loading Feeds", message: error?.localizedDescription ?? "", fromVC: sself)
                
                return
                
            }
            
            resultsInstance.results = response
            
        }
        
    }
    
}

//extension NewFeedVC: UISearchControllerDelegate {
//
//
//
//}
