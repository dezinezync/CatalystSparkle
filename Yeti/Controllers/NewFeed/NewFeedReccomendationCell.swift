//
//  NewFeedReccomendationCell.swift
//  Elytra
//
//  Created by Nikhil Nigade on 18/02/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import UIKit

class NewFeedReccomendationCell: UICollectionViewCell {
    
    static let identifier: String = "newFeedRecommendationCell"

    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var roundedRectView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        clipsToBounds = false
        contentView.clipsToBounds = false
        
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 3)
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOpacity = 0.08
        shadowView.layer.shadowRadius = 6
        shadowView.layer.shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: 6).cgPath
        shadowView.backgroundColor = .clear
        
        roundedRectView.layer.cornerRadius = 12
        roundedRectView.layer.cornerCurve = .continuous
        roundedRectView.clipsToBounds = true
        roundedRectView.backgroundColor = .systemBackground
        
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        shadowView.layer.shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: 6).cgPath
        
    }
    
    override var isHighlighted: Bool {
        
        didSet {
            
            UIView.animateKeyframes(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) { [weak self] in
                
                if self?.isHighlighted == true {
                    self?.shadowView.layer.shadowOpacity = 0.15
                    self?.shadowView.layer.shadowRadius = 8
                }
                else {
                    self?.shadowView.layer.shadowOpacity = 0.08
                    self?.shadowView.layer.shadowRadius = 6
                }
                
            } completion: { (_) in }
            
        }
        
    }

}

extension NewFeedReccomendationCell {
    
    static func register(_ cv: UICollectionView) {
        
        let nib = UINib(nibName: "NewFeedReccomendationCell", bundle: nil)
        cv.register(nib, forCellWithReuseIdentifier: NewFeedReccomendationCell.identifier)
        
    }
    
}
