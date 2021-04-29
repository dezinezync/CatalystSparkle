//
//  FeedTitleView.swift
//  Elytra
//
//  Created by Nikhil Nigade on 02/12/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

import UIKit

@objc final public class FeedTitleView: UIView {

    @objc public let countLabel: UILabel = UILabel.init()
    @objc public let faviconView: UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
    @objc public let titleLabel: UILabel = UILabel.init()
    
    public var shouldBeVisible: Bool = false
    
    convenience init () {
        self.init(frame: CGRect.zero)
        setup()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    /**
     * When the navigation sets up its context and subviews
     * it expects all subviews to be visible during its animation
     * and after that animation is fully committed.
     *
     * We control the newValue here.
     */
    public override var alpha: CGFloat {
        get {
            super.alpha
        }
        set {
            super.alpha = shouldBeVisible ? newValue : 0
        }
    }
    
    func setup () {
        
        let stackView = UIStackView.init(frame: self.bounds)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal;
        stackView.distribution = .equalSpacing;
        stackView.alignment = .center;
        stackView.spacing = 4;
        
        addSubview(stackView)
        
        stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        
        countLabel.numberOfLines = 1
        countLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        countLabel.textColor = UIColor.secondaryLabel
        countLabel.textAlignment = .center
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.text = "0 Unread"
        
        countLabel.sizeToFit()
        
        addSubview(countLabel)
        
        // pin the stackview above the count label with spacing of 2pt
        stackView.bottomAnchor.constraint(equalTo: countLabel.topAnchor, constant:-2).isActive = true
        
        countLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        countLabel.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        
        // make the view only as tall as its content (countLabel being the last view)
        bottomAnchor.constraint(equalTo: countLabel.bottomAnchor).isActive = true
        
        faviconView.contentMode = .scaleAspectFit
        faviconView.clipsToBounds = true
        faviconView.translatesAutoresizingMaskIntoConstraints = false
        faviconView.layer.cornerRadius = 3
        faviconView.layer.cornerCurve = .continuous;
        
        faviconView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        faviconView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        stackView.addArrangedSubview(faviconView)

        titleLabel.numberOfLines = 1
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = UIColor.label
        
        titleLabel.sizeToFit()
        
        stackView.addArrangedSubview(titleLabel)
        
        setNeedsLayout()
        
    }

}
