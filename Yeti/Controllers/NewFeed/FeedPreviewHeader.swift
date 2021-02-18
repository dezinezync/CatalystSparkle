//
//  FeedPreviewHeader.swift
//  Elytra
//
//  Created by Nikhil Nigade on 18/02/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import UIKit

class FeedPreviewHeader: UICollectionReusableView {
    
    static let identifier = "FeedPreviewHeader"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.isHidden = false
        subtitleLabel.isHidden = false
    }
    
}

extension FeedPreviewHeader {
    
    static func register(_ collectionView: UICollectionView) {
        
        let nib = UINib(nibName: "FeedPreviewHeader", bundle: nil)
        
        collectionView.register(nib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: FeedPreviewHeader.identifier)
        
    }
    
}
