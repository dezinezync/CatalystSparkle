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
    
    @objc weak var moveFoldersDelegate: (NSObject & MoveFoldersDelegate)?
    
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
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder = "#topic or Website URL"
        sc.searchBar.accessibilityHint = sc.searchBar.placeholder
        sc.searchBar.textContentType = .URL
        sc.searchBar.keyboardType = .URL
        sc.searchBar.autocapitalizationType = .none
        sc.searchBar.delegate = self
        sc.searchBar.searchTextField.delegate = self
        sc.delegate = self
        
        (sc.searchResultsController as! NewFeedResultsVC).moveFoldersDelegate = self.moveFoldersDelegate
        
        return sc
        
    }()
    
    private var isLoading: Bool = false {
        
        didSet {
            
            guard let resultsVC = searchController.searchResultsController as? NewFeedResultsVC else {
                return
            }
            
            resultsVC.isLoading = self.isLoading
            
        }
        
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        title = "New Feed"
        
        setupCollectionView()
        setupNavBar()
        
    }
    
    // MARK: - Setups
    func setupCollectionView() {
        
        collectionView.backgroundColor = UIColor.init(dynamicProvider: { (trait: UITraitCollection) -> UIColor in
                
            if trait.userInterfaceStyle == .light {
                return .systemGroupedBackground
            }
            
            return .black
            
        })
        
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        
        NewFeedReccomendationCell.register(collectionView)
        
    }
    
    func setupNavBar() {
        
        navigationItem.hidesSearchBarWhenScrolling = false
        
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

extension NewFeedVC: UISearchResultsUpdating, UISearchBarDelegate, UITextFieldDelegate, UISearchControllerDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        guard (searchController.searchBar.text ?? "").contains("#") == true else {
            return
        }
        
        searchBarTextDidEndEditing(searchController.searchBar)
        
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        
        if let resultsInstance = searchController.searchResultsController as? NewFeedResultsVC {
            
            resultsInstance.results = nil
            resultsInstance.isLoading = false
            
        }
        
        return true
        
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
        guard isLoading == false else {
            return
        }
        
        guard let text = searchBar.text else {
            return
        }
        
        guard let resultsInstance = searchController.searchResultsController as? NewFeedResultsVC else {
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
            
            searchTopic(stripped)
            
        }
        else {
            
            resultsInstance.results = nil
            
            guard text.isValidURL == true, let url = URL(string: text) else {
                return
            }
            
            searchURL(url, isYoutube: false)
            
        }
        
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        
        isLoading = false
        
        guard let resultsInstance = self.searchController.searchResultsController as? NewFeedResultsVC else {
            return
        }
        
        resultsInstance.results = nil
        
    }
    
    //MARK: - Networking
    
    func searchTopic(_ topic: String) {
        
        let locale = Locale.current.languageCode ?? "en"
        
        isLoading = true
        
        guard let resultsInstance = self.searchController.searchResultsController as? NewFeedResultsVC else {
            isLoading = false
            return
        }
        
        FeedsLib.shared.getRecommendations(topic: topic.lowercased(), locale: locale) { [weak self] (error: Error?, response: RecommendationsResponse?) in
            
            guard let sself = self else {
                return
            }
            
            if sself.searchController.searchBar.isFirstResponder == true {
                sself.searchController.searchBar.resignFirstResponder()
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
    
    func searchURL(_ url: URL, isYoutube: Bool?) {
        
        if url.absoluteString.contains("youtube.com") == true, url.absoluteString.contains("videos.xml") == false,
           isYoutube == false {
            
            MyFeedsManager._checkYoutubeFeed(url) { [weak self] (responseObject, _, _) in
                
                guard let url = responseObject as? URL else {
                    return
                }
                
                self?.searchURL(url, isYoutube: true)
                
            } error: { (error, _, _) in
                
                guard let error = error else {
                    return
                }
                
                AlertManager.showGenericAlert(withTitle: "An Error Occurred", message: error.localizedDescription)
                
            }
            
            return
            
        }
        
        let path: String = url.path
        
        if (path.contains("/feed") || path.contains("/rss") || path.contains("xml") || path.contains("json")) == false {
            
            guard let resultsInstance = searchController.searchResultsController as? NewFeedResultsVC else {
                return
            }
            
            FeedsLib.shared.getFeedInfo(url: url) { (error: Error?, response: FeedInfoResponse?) in
                
                if let error = error {
                    AlertManager.showGenericAlert(withTitle: "An Error Occurred", message: error.localizedDescription)
                    return
                }
                
                guard let response = response else {
                    return
                }
                
                guard let results = response.results, results.count > 0 else {
                    return
                }
                
                let items: [FeedRecommendation] = results.map { $0.toRecommendation() }
                
                let recommendationsResponse = RecommendationsResponse()
                recommendationsResponse.feedInfos = items
                
                resultsInstance.results = recommendationsResponse
                
            }
            
            return
            
        }
        
        let item = FeedRecommendation()
        item.id = "feed/\(url.absoluteString)"
        item.title = isYoutube == true ? "Youtube Channel" : "Untitled"
        
        let instance = FeedPreviewVC(collectionViewLayout: FeedPreviewVC.layout)
        instance.item = item
        instance.moveFoldersDelegate = self.moveFoldersDelegate
        
        let nav = UINavigationController(rootViewController: instance)
        self.present(nav, animated: true, completion: nil)
        
    }
    
}
