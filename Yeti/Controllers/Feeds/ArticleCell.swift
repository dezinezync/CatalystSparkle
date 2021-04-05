//
//  ArticleCell.swift
//  Elytra
//
//  Created by Nikhil Nigade on 16/03/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import UIKit
import Models
import SDWebImage
import DBManager
import Combine

class ArticleCell: UITableViewCell {
    
    static let identifier = "articleCell"
    
    @IBOutlet var authorLabel: UILabel!
    @IBOutlet var coverImage: UIImageView!
    @IBOutlet var markerView: UIImageView!
    @IBOutlet var summaryLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var titleLabelWidthConstraint: NSLayoutConstraint!
    
    var cancellables: [AnyCancellable] = []
    
    weak var article: Article?
    var feedType: FeedType!
    
    fileprivate var isShowingCover: Bool {
        return !coverImage.isHidden
    }
    
    fileprivate var faviconTask: SDWebImageOperation?
    fileprivate var coverTask: SDWebImageOperation?
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        coverImage.layer.cornerRadius = 3
        coverImage.layer.cornerCurve = .continuous
        
        titleLabel.textColor = .label
        summaryLabel.textColor = .secondaryLabel
        authorLabel.textColor = .secondaryLabel
        timeLabel.textColor = .secondaryLabel
        
        selectedBackgroundView = UIView()
        
        #if targetEnvironment(macCatalyst)
        selectedBackgroundView?.backgroundColor = .systemFill
        selectedBackgroundView?.layer.cornerRadius = 6
        selectedBackgroundView?.layer.masksToBounds = true
        #else
        selectedBackgroundView?.backgroundColor = tintColor.withAlphaComponent(0.3)
        #endif
        
        separatorInset = .zero
        
        resetUI()
        
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        guard let sbv = selectedBackgroundView,
              sbv.superview != nil,
              traitCollection.userInterfaceIdiom == .mac else {
            return
        }
        
        sbv.frame = bounds.insetBy(dx: 12, dy: 6)
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        resetUI()
        
        for o in cancellables {
            o.cancel()
        }
        
        cancellables = []
        
    }
    
    func resetUI() {
        
        coverImage.sd_cancelCurrentImageLoad()
        
        for label in [titleLabel, summaryLabel, authorLabel, timeLabel] {
            label?.text = nil
        }
        
        coverImage.image = nil
        coverImage.isHidden = true
        
        markerView.image = nil
        
        faviconTask?.cancel()
        faviconTask = nil
        
        coverTask?.cancel()
        coverTask = nil
        
        semanticContentAttribute = .unspecified
        titleLabel.textAlignment = .left
        authorLabel.textAlignment = .left
        
    }
    
    override func tintColorDidChange() {
        
        super.tintColorDidChange()
        
        updateMarkerView()
        
        #if targetEnvironment(macCatalyst)
        selectedBackgroundView?.backgroundColor = .systemFill
        #else
        selectedBackgroundView?.backgroundColor = tintColor.withAlphaComponent(0.3)
        #endif
        
    }
    
    // MARK: - Configure
    var showImage: Bool {
        
        if SharedPrefs.articleCoverImages == false {
            return false
        }
        
        if SharedPrefs.imageBandwidth == ImageBandwidthOption.loadingNever {
            return false
        }
        
        else if SharedPrefs.imageBandwidth == ImageBandwidthOption.loadingOnlyWireless {
            return CheckWiFi()
        }
        
        return true
        
    }
    
    var isMicroblogPost: Bool {
        
        guard let article = article else {
            return false
        }
        
        if article.title?.isEmpty == true && article.content.count > 0 {
            
            if article.textFromContent != nil {
                return true
            }
            
            // find the first para
            let firstPara = article.content.reduce(nil, { (prev, cur) -> Content in
                
                if prev != nil && prev?.type == "paragraph" {
                    return prev!
                }
                
                return cur
                
            })
            
            return firstPara != nil
            
        }
        
        return false
        
    }
    
    func configure(_ article: Article, feedType: FeedType) {
        
        self.article = article
        self.feedType = feedType
        
        guard self.article != nil else {
            return
        }
        
        guard let feed = DBManager.shared.feedForID(article.feedID) else {
            return
        }
        
        configureTitle(feed: feed)
        
        if showImage == false {
            coverImage.isHidden = true
        }
        else {
            
            var coverImageURL = article.coverImage
            
            if coverImageURL == nil, article.content.count > 0 {
                
                // find the first image
                if let content = article.content.first(where: { (c) -> Bool in
                    
                    return c.type == "image"
                    
                }) {
                    article.coverImage = content.url
                    coverImageURL = article.coverImage
                }
                
            }
            
            configureCoverImage(url: coverImageURL)
        }
        
        configureSummary()
        configureAuthor(feed: feed)
        
        titleLabel.accessibilityValue = titleLabel.text?.replacingOccurrences(of: " | ", with: " by ")
        
        if (Paragraph.languageDirection(forText: article.title ?? titleLabel.text ?? article.summary ?? "") == NSLocale.LanguageDirection.rightToLeft) {
            
            semanticContentAttribute = .forceRightToLeft
            textLabel?.textAlignment = .right
            authorLabel.textAlignment = .right
            
        }
        
        let width = bounds.size.width - 48
        
        titleLabel.preferredMaxLayoutWidth = width - (isShowingCover ? 92 : 4) // 80 + 12
        
        titleLabelWidthConstraint.constant = titleLabel.preferredMaxLayoutWidth
        
        summaryLabel.preferredMaxLayoutWidth = width
        
        timeLabel.preferredMaxLayoutWidth = 92
        
        authorLabel.preferredMaxLayoutWidth = titleLabel.preferredMaxLayoutWidth - 24 - 12 - timeLabel.preferredMaxLayoutWidth
        
        let timestamp = RelativeDateTimeFormatter().localizedString(for: article.timestamp, relativeTo: Date())
        
        timeLabel.text = timestamp
        timeLabel.accessibilityLabel = timestamp
        
        updateMarkerView()
        
        article.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateMarkerView()
            }
            .store(in: &cancellables)
        
    }
    
    func configureTitle(feed: Feed) {
        
        guard let article = self.article else {
            return
        }
        
        if isMicroblogPost == true {
            
            titleLabel.text = article.textFromContent
            titleLabel.numberOfLines = max(3, SharedPrefs.previewLines)
            titleLabel.font = .preferredFont(forTextStyle: .body)
            
        }
        else {
            
            titleLabel.text = article.title
            titleLabel.font = .preferredFont(forTextStyle: .headline)
            
        }
        
        guard feedType != .natural && feedType != .author else {
            return
        }
        
        guard showImage == true else {
            return
        }
        
        let paraStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paraStyle.lineSpacing = 24
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: titleLabel.font!,
            .foregroundColor: titleLabel.textColor!
        ]
        
        let attrs = NSMutableAttributedString(string: " \(titleLabel.text ?? "")", attributes: attributes)
        
        var attachment = NSTextAttachment()
        
        configureTitleFavicon(attachment: attachment, url: feed.faviconURI, feed: feed)
        
        // positive offsets push it up, negative push it down
        // this is similar to NSRect
        let fontSize: Double = Double(titleLabel.font.pointSize)
        let baseLine: Double = 17 // compute our expected using this
        let expected: Double = 7 // from the above, A:B :: C:D
        var yOffset: Double = (baseLine / fontSize) * expected * -1
        
        yOffset += 6
        
        #if targetEnvironment(macCatalyst)
        attachment.bounds = CGRect(x: 0, y: yOffset, width: 16, height: 16)
        #else
        attachment.bounds = CGRect(x: 0, y: yOffset, width: 24, height: 24)
        #endif
        
        let attachmentString = NSMutableAttributedString(attachment: attachment)
        
        attachmentString.append(attrs)
        
        titleLabel.attributedText = attachmentString
        
    }
    
    func configureCoverImage(url: URL?) {
        
        guard let url = url else {
            coverImage.isHidden = true
            return
        }
        
        guard url.absoluteString.contains("core/emoji") == false else {
            coverImage.isHidden = true
            return
        }
        
        coverImage.isHidden = false
        
        var proxyURL = url
        
        if proxyURL.absoluteString.contains(".gif") {
            
            // only load covers for GIFs. Loading the full gif can
            // cause a lot of memory to be used for unpacking the
            // gif data and eventually crashing the app.
            
            let proxyPath = url.absoluteString.path(forImageProxy: false, maxWidth: coverImage.bounds.size.width, quality: 0.9, firstFrameForGIF: true, useImageProxy: true, sizePreference:  SharedPrefs.imageBandwidth, forWidget: false)
            
            if let aURL = URL(string: proxyPath) {
                proxyURL = aURL
            }
            
        }
        
        else if SharedPrefs.imageProxy == true {
            
            let proxyPath = url.absoluteString.path(forImageProxy: false, maxWidth: coverImage.bounds.size.width, quality: 0.9, firstFrameForGIF: false, useImageProxy: true, sizePreference:  SharedPrefs.imageBandwidth, forWidget: false)
            
            if let aURL = URL(string: proxyPath) {
                proxyURL = aURL
            }
             
        }
        
        coverImage.contentMode = .center
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self, weak coverImage] in
            
            self?.coverTask = SDWebImageManager.shared.loadImage(with: proxyURL, options: [.scaleDownLargeImages, .retryFailed], context: nil, progress: nil, completed: { (image, data, error, cacheType, finished, imageURL) in
                
                guard finished == true else {
                    return
                }
                
                if let err = error,
                    proxyURL == url
                        && ((err as NSError).userInfo[SDWebImageErrorDownloadStatusCodeKey] as? Int) ?? 0 == 404 {
                    
                    #if DEBUG
                    print("Failed to download cover image with URL:", proxyURL)
                    #endif
                    
                    return
                    
                }
                
                guard let c = coverImage else {
                    return
                }
                
                DispatchQueue.main.async {
                    
                    c.image = image
                    c.contentMode = .scaleAspectFill
                    
                }
                
            })
            
        }
        
    }
    
    func configureSummary() {
        
        let previewLines = SharedPrefs.previewLines
        
        guard previewLines > 0 else {
            summaryLabel.isHidden = true
            summaryLabel.text = nil
            return
        }
        
        summaryLabel.isHidden = false
        summaryLabel.numberOfLines = previewLines
        summaryLabel.text = article?.summary
        
    }
    
    func configureAuthor(feed: Feed) {
        
        authorLabel.isHidden = false
        
        var format = " - %@"
        
        if let author = article?.author, author.isEmpty == false {
            
            authorLabel.text = author.stripHTML()
            
        }
        else {
            
            authorLabel.text = nil
            format = "%@"
            
        }
        
        if feedType != .natural {
            
            let feedTitle = feed.displayTitle
            
            if feedTitle != authorLabel.text {
                
                let text = (authorLabel.text ?? "")?.appendingFormat(format, feedTitle).trimmingCharacters(in: .whitespacesAndNewlines)
                
                authorLabel.text = text
                
            }
            
        }
        
    }
    
    func updateMarkerView() {
     
        guard let a = article else {
            return
        }
        
        if a.state == .Bookmarked && feedType != .bookmarks {
            
            markerView.tintColor = .systemOrange
            markerView.image = UIImage(systemName: "bookmark.fill")
            
        }
        else if a.state == .Unread {
            
            markerView.tintColor = SharedPrefs.tintColor
            markerView.image = UIImage(systemName: "largecircle.fill.circle")
            
        }
        else {
            
            markerView.tintColor = .secondaryLabel
            markerView.image = UIImage(systemName: "smallcircle.fill.circle")
            
        }
        
    }
    
}

extension ArticleCell {
    
    static func register(_ tableView: UITableView) {
        
        let nib = UINib(nibName: "ArticleCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: ArticleCell.identifier)
        
    }
    
    func configureTitleFavicon(attachment: NSTextAttachment, url: URL?, feed: Feed) {
        
        if faviconTask != nil {
            faviconTask?.cancel()
            faviconTask = nil
        }
        
        let config = UIImage.SymbolConfiguration(font: titleLabel.font!)
        
        attachment.image = UIImage(systemName: "square.dashed", withConfiguration: config)
        
        titleLabel.setNeedsDisplay()
        
        guard var url = url else {
            return
        }
        
        if SharedPrefs.imageProxy == true {
            let a = feed.faviconProxyURI(size: attachment.bounds.size.width) ?? url
            
            url = a
        }
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self, weak attachment] in
            
            self?.faviconTask = SDWebImageManager.shared.loadImage(with: url, options: [], progress: nil, completed: { (image, data, error, cacheType, finished, imageURL) in
                
                guard let sself = self,
                      let a = attachment else {
                    return
                }
                
                guard error == nil else {
                    
                    #if DEBUG
                    print("Failed to fetch favicon at:", url, error!.localizedDescription)
                    #endif
                    
                    return
                    
                }
                
                guard let image = image else {
                    return
                }
                
                var bounds = a.bounds
                bounds.origin = .zero
                
                guard let rounded = image.sd_roundedCornerImage(withRadius: (3 * UIScreen.main.scale), corners: .allCorners, borderWidth: 0, borderColor: nil) else {
                    return
                }
                
                DispatchQueue.main.async {
                    
                    a.image = rounded
                    
                    sself.titleLabel.setNeedsDisplay()
                    
                }
                
            })
            
        }
        
    }
    
}
