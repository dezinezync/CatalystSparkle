import Foundation
import YapDatabase
import SwiftYapDatabase
import Models
import Combine

/// Have the changes been fully synced with our local store?
private let SYNCED_CHANGES = "syncedChanges"

public enum CollectionNames: String, CaseIterable {
    
    case sync
    case localNames
    case feeds
    case folders
    case articles
    case articlesContent
    case articlesFulltext
    case settings
    case user
    
}

public enum GroupNames: String, CaseIterable {
    
    case articles
    case feeds
    case folders
    
}

public extension Notification.Name {
    static let userUpdated = Notification.Name(rawValue: "com.yeti.note.userDidUpdate")
    static let feedsUpdated = Notification.Name(rawValue: "feedsUpdated")
    static let foldersUpdated = Notification.Name(rawValue: "foldersUpdated")
}

private let DB_VERSION_TAG = "2021-03-29 09:30AM IST"

extension NSNotification.Name {
//    static let YapDatabaseModifiedNotification = NSNotification.Name("YapDatabaseModifiedNotification")
    public static let DBManagerDidUpdate = Notification.Name("DBManagerDidUpdate")
}

public let titleWordCloudKey = "titleWordCloud"

public let notificationsKey = "notifications"

@objcMembers public final class DBManager: NSObject {
    
    public static let shared = DBManager()
    
    public var syncCoordinator: SyncCoordinator?
    
    fileprivate var _lastUpdated: Date!
    
    public var lastUpdated: Date? {
        
        get {
            
            if _lastUpdated != nil {
                return _lastUpdated
            }
            
            var d: String?
            
            bgConnection.read { (t) in
                
                d = t.object(forKey: "lastUpdate", inCollection: .sync) as? String
                
            }
            
            guard let ds = d else {
                return nil
            }
            
            let date = Subscription.dateFormatter.date(from: ds)
            
            _lastUpdated = date
            
            return date
            
        }
        
        set {
            
            willChangeValue(for: \.lastUpdated)
            
            _lastUpdated = newValue
            
            didChangeValue(for: \.lastUpdated)
            
            bgConnection.readWrite { (t) in
                
                guard let value = newValue else {
                    
                    t.removeObject(forKey: "lastUpdate", inCollection: .sync)
                    
                    return
                }
                
                let ds = Subscription.dateFormatter.string(from: value)
                
                t.setObject(ds, forKey: "lastUpdate", inCollection: .sync)
                
            }
            
        }
        
    }
    
    public override init() {
        
        super.init()
        
        setupDatabase(self.database)
        setupViews(self.database)
        
        setupNotifications(self.database)
        
    }
    
    // MARK: - DB & Connections
    fileprivate var _database: YapDatabase!
    
    public lazy var database: YapDatabase = {
        
        guard _database == nil else {
            return _database
        }
        
        self.writeQueue.sync {
            
            let fm = FileManager.default
            #if DEBUG
            let dbName = "elytra-v2.3.0k-debug.sqlite"
            #else
            let dbName = "elytra-v2.3.0b.sqlite"
            #endif
            
            guard let baseURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                fatalError("DB Path could not be constructed")
            }
            
            try? fm.createDirectory(at: baseURL, withIntermediateDirectories: true, attributes: nil)
            
            let dbURL = baseURL.appendingPathComponent(dbName, isDirectory: false)
            
            guard let db = YapDatabase(url: dbURL) else {
                fatalError("Could not open DB")
            }
            
//            #if DEBUG
//            let c = db.newConnection()
//            c.readWrite { t in
//                t.removeAllObjectsInAllCollections()
//            }
//            #endif
            
            _database = db
            
        }
        
        return _database
    }()
    
    public lazy var uiConnection: YapDatabaseConnection = {
        
        var config = database.newConnection()
        
        config.objectCacheEnabled = false
        config.metadataCacheLimit = 50
        
        config.enableExceptionsForImplicitlyEndingLongLivedReadTransaction()
        config.beginLongLivedReadTransaction()
        
        return config
        
    }()
    
    public lazy var bgConnection: YapDatabaseConnection = {
        
        let config = YapDatabaseConnectionConfig()
        config.objectCacheEnabled = false
        config.metadataCacheEnabled = false
        
        return database.newConnection(config)
        
    }()
    
    public lazy var countsConnection: YapDatabaseConnection = {
        
        let config = YapDatabaseConnectionConfig()
        config.objectCacheEnabled = false
        config.metadataCacheLimit = 200
        
        let c = database.newConnection(config)
        
        c.enableExceptionsForImplicitlyEndingLongLivedReadTransaction()
        c.beginLongLivedReadTransaction()
        
        return c
        
    }()
    
    public lazy var readQueue: DispatchQueue = {
        return DispatchQueue(label: "readQueue", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
    }()
    
    public lazy var writeQueue: DispatchQueue = {
        return DispatchQueue(label: "writeQueue", qos: .userInteractive, attributes: [], autoreleaseFrequency: .workItem, target: nil)
    }()
    
    // MARK: - Setups
    fileprivate var cancellables: [AnyCancellable] = []
    
    internal func setupNotifications(_ db: YapDatabase) {
        
        NotificationCenter.default.publisher(for: .YapDatabaseModified, object: db)
            .receive(on: DispatchQueue.global(qos: .default))
            .sink { [weak self] (note) in
                
                guard let sself = self else {
                    return
                }
                
                // Move connections to the latest commit
                let notes: [Notification] = sself.uiConnection.beginLongLivedReadTransaction()
                let notes2: [Notification] = sself.countsConnection.beginLongLivedReadTransaction()
                
                var uniqueNotes: Set<Notification> = Set(notes)
                uniqueNotes = uniqueNotes.union(Set(notes2))
                
                let notifications: [Notification] = Array(uniqueNotes)
                
                if notifications.count == 0 {
                    // nothing changed.
                    return
                }
                
                // Notify our observors
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .DBManagerDidUpdate, object: self, userInfo: [notificationsKey: notifications])
                }

            }
            .store(in: &cancellables)
        
    }
    
    // MARK: - User
    fileprivate var _user: User?
    public var user: User? {
        
        get {
            
            guard let _user = _user else {
                var u: User?
                
                uiConnection.read { (t) in
                    
                    u = t.object(forKey: "user", inCollection: .user) as? User
                    
                }
                
                if u?.userID != nil, u?.uuid != nil {
                    self._user = u
                }
                
                return self._user
            }
            
            return _user
            
        }
        
        set {
            
            _user = newValue
            setUser(newValue, completion: nil)
            
            var userInfo: [String: Any] = [:]
            
            if _user != nil {
                userInfo["user"] = _user
            }
            
            NotificationCenter.default.post(name: .userUpdated, object: self, userInfo: userInfo)
            
        }
        
    }
    
    public func setUser(_ user: User?, completion: (() -> Void)?) {
        
        writeQueue.async { [weak self] in
            
            self?.bgConnection.asyncReadWrite { (t) in
                
                guard let user = user else {
                    
                    t.removeObject(forKey: "user", inCollection: .user)
                    
                    return
                    
                }
                
                t.setObject(user, forKey: "user", inCollection: .user)
                
            }
            
        }
        
    }
    
    // MARK: - Feeds
    fileprivate var _feeds: [Feed] = []
    
    public var feeds: [Feed] {
        
        get {
            
            guard _feeds.count == 0 else {
                return _feeds
            }
            
            var f: [Feed] = []
            
            uiConnection.read({ (t) in
                
                let keys = t.allKeys(inCollection: .feeds)
                
                if keys.count == 0 {
                    return;
                }
                
                for k in keys {
                    
                    let feed = t.object(forKey: k, inCollection: .feeds) as! Feed
                    
                    f.append(feed)
                    
                }
                
            })
            
            _feeds = f
            
            return _feeds
            
        }
        
        set {
            
            _feeds = newValue
            
            NotificationCenter.default.post(name: .feedsUpdated, object: self)
            
            if newValue.count == 0 {
                return
            }
            
            writeQueue.sync { [weak self] in
                
                guard let sself = self else {
                    return
                }
                
                self?.bgConnection.readWrite({ (t) in
                    
                    for f in newValue {
                        
                        let key = "\(f.feedID!)"
                        
                        let metadata = sself._metadataForFeed(f)
                        
                        t.setObject(f, forKey: key, inCollection: .feeds, withMetadata: metadata)
                        
                    }
                    
                })
                
                _preSyncFeedMetadata = [:]
                
            }
            
        }
        
    }
    
    public func feed(for id: UInt) -> Feed? {
        
        return _feeds.first { $0.feedID == id }
        
    }
    
    public func add(feed: Feed) {
        
        update(feed: feed)
        
        feeds.append(feed)
        
    }
    
    fileprivate var _preSyncFeedMetadata: [UInt: FeedMeta] = [:]
    
    fileprivate func _metadataForFeed(_ feed: Feed) -> FeedMeta {
        
        var existing: FeedMeta! = nil
        
        if _preSyncFeedMetadata.count != 0,
           let item = _preSyncFeedMetadata[feed.feedID] {
            
            existing = item
            
        }
        else {
            
            if feed.feedID != nil && feed.url != nil {
                
                let m = FeedMeta(id: feed.feedID, url: feed.url, title: feed.title)
                
                if feed.folderID != nil {
                    m.folderID = feed.folderID
                }
                
                existing = m
                
            }
            
        }
        
        return existing
        
    }
    
    public func metadataForFeed (_ feed: Feed) -> FeedMeta {
        
        var metadata: FeedMeta! = nil
        
        uiConnection.read { (t) in
            
            metadata = t.metadata(forKey: "\(feed.feedID!)", inCollection: .feeds) as? FeedMeta
            
        }
        
        if metadata == nil {
            metadata = _metadataForFeed(feed)
        }
        
        return metadata
        
    }
    
    public func update(feed: Feed) {
        
        let metadata = metadataForFeed(feed)
        
        update(feed: feed, metadata: metadata)
        
    }
    
    public func update(feed: Feed, metadata: FeedMeta) {
        
        let key = "\(feed.feedID!)"
        
        bgConnection.readWrite({ (t) in
            
            t.setObject(feed, forKey: key, inCollection: .feeds, withMetadata: metadata)
            
        })
        
    }
    
    public func feedForID(_ id: UInt) -> Feed? {
        
        return feeds.first { $0.feedID == id }
        
    }
    
    public func bulkUpdate(feeds operation:@escaping ((_ feed: Feed, _ metadta:FeedMeta) -> (Feed, FeedMeta))) {
        
        writeQueue.async { [weak self] in
            
            guard let sself = self else {
                return
            }
            
            sself.bgConnection.readWrite({ (t) in
                
                for feed in sself.feeds {
                    
                    let metadata = sself.metadataForFeed(feed)
                    let op = operation(feed, metadata)
                    
                    let (updatedFeed, updatedMetadata) = op
                    
                    t.setObject(updatedFeed, forKey: "\(updatedFeed.feedID!)", inCollection: .feeds, withMetadata: updatedMetadata)
                    
                }
                
            })
            
        }
        
    }
    
    public func rename(feed: Feed, customTitle: String, completion:((Result<Bool, Error>) -> Void)?) {
        
        let localNameKey = "\(feed.feedID!)"
        
        // if the user provides a clear string, we remove the local name
        if customTitle.count == 0 {
            
            writeQueue.async { [weak self] in
                
                // @TODO: Add CloudCore operation
                
                self?.bgConnection.asyncReadWrite({ (t) in
                    
                    t.removeObject(forKey: localNameKey, inCollection: .localNames)
                    
                    feed.localName = nil
                    
                    guard let completion = completion else {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        completion(.success(true))
                    }
                    
                })
                
            }
            
        }
        else {
            
            writeQueue.async { [weak self] in
                
                // @TODO: Add CloudCore operation
                
                self?.bgConnection.asyncReadWrite({ (t) in
                    
                    t.setObject(customTitle, forKey: localNameKey, inCollection: .localNames)
                    
                    feed.localName = customTitle
                    
                    guard let completion = completion else {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        completion(.success(true))
                    }
                    
                })
                
            }
            
        }
        
    }
    
    public func delete(feed: Feed) {
        
        // remove it from the folders first
        if let folderID = feed.folderID,
           let folder = folder(for: folderID) {
            
            folder.feedIDs = Set(Array(folder.feedIDs).filter { $0 != folderID })
            folder.feeds = folder.feeds.filter { $0 != feed }
            // save the folder struct back to the DB.
            add(folder: folder)
            
        }
        
        feeds = feeds.filter { $0 != feed }
        
        let feedID = feed.feedID
        
        bgConnection.readWrite { [weak self] (t) in
            
            t.removeObject(forKey: "\(feed.feedID!)", inCollection: .feeds)
            
            // Delete all articles for this feed
            guard let txn = t.ext(.articlesView) as? YapDatabaseFilteredViewTransaction else {
                return
            }
            
            var articlesToDelete: [String] = []
            
            txn.enumerateKeysAndMetadata(inGroup: GroupNames.articles.rawValue, with: [], range: NSMakeRange(0, Int(txn.numberOfItems(inGroup: GroupNames.articles.rawValue)))) { _, _ in
                return true
            } using: { c, k, m, index, stop in
                
                guard let meta = m as? ArticleMeta else {
                    return
                }
                
                if meta.feedID == feedID {
                    
                    articlesToDelete.append(k)
                    
                }
                
            }
            
            guard articlesToDelete.count > 0 else {
                // nothing to delete.
                return
            }
            
            for key in articlesToDelete {
                self?._delete(articleID: key, transaction: t)
            }
            
        }
        
        
    }
    
    // MARK: - Folders
    fileprivate var _folders: [Folder] = []
    
    public var folders: [Folder] {
        
        get {
            
            guard _folders.count == 0 else {
                return _folders
            }
            
            var f: [Folder] = []
            
            let connection = database.newConnection()
            
            connection.read { [weak self] (t) in
                
                let keys = t.allKeys(inCollection: .folders)
                
                for k in keys {
                    
                    if let folder = t.object(forKey: k, inCollection: .folders) as? Folder {
                    
                        if folder.feedIDs.count > 0 {
                            
                            for id in folder.feedIDs {
                                
                                if let feed = self?.feedForID(id) {
                                    
                                    folder.feeds.append(feed)
                                    
                                    feed.folderID = folder.folderID
                                    
                                }
                                
                            }
                            
                        }
                        
                        f.append(folder)
                        
                    }
                    
                }
                
            }
            
            _folders = f
            
            return _folders
            
        }
        
        set {
            
            _folders = newValue
            
            NotificationCenter.default.post(name: .foldersUpdated, object: self)
            
            guard newValue.count > 0 else {
                return
            }
            
            if feeds.count > 0 {
                
                // Map feeds to folders
                for folder in _folders {
                    
                    folder.feedIDs.forEach { (feedID) in
                        
                        if let feed = feeds.first(where: { $0.feedID == feedID }) {
                            
                            feed.folderID = folder.folderID
                            
                            folder.feeds.append(feed)
                            
                        }
                        
                    }
                    
                }
                
            }
            
            writeQueue.async { [weak self] in
                
                self?.bgConnection.asyncReadWrite { (t) in
                    
                    for folder in newValue {
                        
                        let copy = folder.codableCopy()
                        copy.feeds = []
                        
                        t.setObject(copy, forKey: "\(copy.folderID!)", inCollection: .folders)
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    public func folder(for id: UInt) -> Folder? {
        
        return self.folders.first { (f) -> Bool in
            return f.folderID == id
        }
        
    }
    
    public func add(folder: Folder) {
        
        bgConnection.readWrite { (t) in
            
            t.setObject(folder, forKey: "\(folder.folderID!)", inCollection: .folders)
            
        }
        
    }
    
    public func update(folder: Folder) {
        
        let key = "\(folder.folderID!)"
        
        bgConnection.readWrite({ (t) in
            
            t.setObject(folder, forKey: key, inCollection: .folders)
            
        })
        
    }
    
    public func delete(folder: Folder) {
        
        bgConnection.readWrite { [weak self] (t) in
            
            guard let sself = self else {
                return
            }
            
            // unset all feeds
            for feedID in folder.feedIDs {
                
                if let feed = sself.feedForID(feedID) {
                    
                    feed.folderID = nil
                    
                    let metadata = sself.metadataForFeed(feed)
                    
                    t.setObject(feed, forKey: "\(feed.feedID!)", inCollection: .feeds, withMetadata: metadata)
                    
                }
                
            }
            
            t.removeObject(forKey: "\(folder.folderID!)", inCollection: .folders)
            
        }
        
    }
    
    // MARK: - Articles
    
    public func article(for id: String, feedID: UInt) -> Article? {
        
        var a: Article! = nil
        
        uiConnection.read { (t) in
            
            a = t.object(forKey: "\(id)", inCollection: .articles) as? Article
            
        }
        
        return a
        
    }
    
    public func content(for articleID: String) -> [Content]? {
        
        var c: [Content]! = nil
        
        uiConnection.read { (t) in
            
            c = t.object(forKey: articleID, inCollection: .articlesContent) as? [Content]
            
        }
        
        return c
        
    }
    
    public func fullText(for articleID: String) -> [Content]? {
        
        var c: [Content]! = nil
        
        uiConnection.read { (t) in
            
            c = t.object(forKey: articleID, inCollection: .articlesFulltext) as? [Content]
            
        }
        
        return c
        
    }
    
    public func add (article: Article) {
        
        add(articles: [article], strip: true)
        
    }
    
    public func add(article: Article, strip: Bool) {
        
        guard article.identifier != nil, article.feedID != 0 else {
            fatalError("Error adding article with no identifer or feed ID to the database.")
        }
        
        add(articles: [article], strip: strip)
        
    }
    
    public func add(articles: [Article], strip: Bool) {
        
        guard articles.count > 0 else {
            return
        }
        
        let now = Date()
        
        bgConnection.readWrite { (t) in
            
            for a in articles {
                
                if a.read == false,
                   a.timestamp.timeIntervalSince(now) < -1209600 {
                    
                    // articles older than 2 weeks are marked as read
                    a.read = true
                    
                }
                
                if a.content.count > 0 {
                    
                    if a.summary == nil {
                        
                        if var summary = a.textFromContent {
                            
                            if summary.count > 200 {
                                
                                summary = ((summary as NSString).substring(to: 197)) as String
                                
                                summary += "..."
                                
                            }
                            
                            a.summary = summary
                            
                        }
                        
                    }
                    
                }
                
                if a.content.count > 0 {
                    t.setObject(a.content, forKey: a.identifier!, inCollection: .articlesContent)
                }
                
                if strip == true {
                    a.content = []
                }
                
                let charSet: CharacterSet = .whitespaces
                var punctuations: CharacterSet = .punctuationCharacters
                
                punctuations.insert(charactersIn: ",./\\{}[]()!~`“‘…–≠=-÷:;&")
                
                let title = a.title ?? ""
                
                let components: [String]? = title.isEmpty == true ? nil : title.lowercased()
                    .trimmingCharacters(in: charSet)
                    .components(separatedBy: punctuations)
                    .filter { $0.count > 0 && $0.isEmpty == false }
                
                let metadata = ArticleMeta(feedID: a.feedID, read: a.read, bookmarked: a.bookmarked, fulltext: a.fulltext, timestamp: a.timestamp, titleWordCloud: components, author: a.author)
                
                t.setObject(a, forKey: a.identifier!, inCollection: .articles, withMetadata: metadata)
                
            }
            
        }
        
    }
    
    public func add (fullText: [Content], articleID: String) {
        
        guard fullText.count != 0 else {
            return
        }
        
        bgConnection.readWrite { (t) in
            
            t.setObject(fullText, forKey: "\(articleID)", inCollection: .articlesFulltext)
            
        }
        
    }
    
    public func delete(fullTextFor articleID: String) {
        
        bgConnection.readWrite { (t) in
            
            t.removeObject(forKey: "\(articleID)", inCollection: .articlesFulltext)
            
        }
        
    }
    
    public func delete(article: Article) {
        
        _delete(articleID: article.identifier)
        
    }
    
    fileprivate func _delete(articleID: String) {
        
        bgConnection.readWrite({ (t) in
            
            _delete(articleID: articleID, transaction: t)
            
        })
        
    }
    
    fileprivate func _delete(articleID: String, transaction: YapDatabaseReadWriteTransaction) {
        
        transaction.removeObject(forKey: articleID, inCollection: .articles)
        transaction.removeObject(forKey: articleID, inCollection: .articlesContent)
        transaction.removeObject(forKey: articleID, inCollection: .articlesFulltext)
        
    }
    
//    public func delete(allArticlesFor feed: Feed) {
//
//        let col = "\(CollectionNames.articles.rawValue):\(feed.feedID!)"
//
//        bgConnection.asyncReadWrite({ (t) in
//
//            let keys = t.allKeys(inCollection: col)
//
//            t.removeAllObjects(inCollection: col)
//
//            t.removeObjects(forKeys: keys, inCollection: .articlesContent)
//
//            t.removeObjects(forKeys: keys, inCollection: .articlesFulltext)
//
//            t.removeObject(forKey: "\(feed.feedID!)", inCollection: .feeds)
//
//        })
//
//    }
    
}

// MARK: - Bulk Operations
extension DBManager {
    
    public func resetAccount(completion: (() -> Void)?) {
        
        bgConnection.asyncReadWrite { t in
            
            t.removeAllObjectsInAllCollections()
            
        } completionBlock: { [weak self] in
            
            DispatchQueue.main.async {
                self?.user = nil
                self?.feeds = []
                self?.folders = []
                
                completion?()
            }
            
        }

        
    }
    
    public func purgeDataForResync (completion: (() -> Void)?) {
     
        purgeFeedsForResync { [weak self] in
            
            self?.bgConnection.asyncReadWrite { (transaction) in
                
                transaction.removeAllObjects(inCollection: .articlesContent)
                transaction.removeAllObjects(inCollection: .articlesFulltext)
                
                transaction.removeAllObjects(inCollection: .articles)
                transaction.removeAllObjects(inCollection: .sync)
                
                DispatchQueue.main.async {
                    
                    completion?()
                    
                }
                
            }
            
        }
        
    }
    
    public func purgeFeedsForResync (completion: (() -> Void)?) {
        
        var preSyncMetadata: [UInt: FeedMeta] = [:]
        
        for feed in feeds {
            
            let metadata = self.metadataForFeed(feed)
            
            if metadata.localNotifications == true || metadata.readerMode == true {
                preSyncMetadata[feed.feedID] = metadata
            }
            
        }
        
        bgConnection.readWrite { (transaction) in
            
            transaction.removeAllObjects(inCollection: .feeds)
            transaction.removeAllObjects(inCollection: .folders)
            
        }
        
        feeds = []
        folders = []
        
       _preSyncFeedMetadata = preSyncMetadata
        
        DispatchQueue.main.async {
            completion?()
        }
        
    }
    
    public func cleanupDatabase() {
        
        // remove articles older than 1 month from the DB.
        let interval = Date().timeIntervalSince1970
        
        writeQueue.async { [weak self] in
            
            guard let sself = self else {
                return
            }
        
            sself.bgConnection.asyncReadWrite { (t) in
                
                var keys = t.allKeys(inCollection: .articles).sorted()
                
                guard keys.count > 20 else {
                    return
                }
                
                // check the last 20 items
                keys = keys.suffix(20)
                
                for key in keys {
                    
                    guard let metadata = t.metadata(forKey: key, inCollection: .articles) as? ArticleMeta else {
                        continue
                    }
                    
                    let timestamp = metadata.timestamp
                    
                    if ((interval - timestamp) > 2592000) {
                        
                        sself._delete(articleID: key, transaction: t)
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
}

// MARK: - DB Registrations

public enum DBManagerViews: String {
    
    case rootView
    case feedView
    case articlesView
    case unreadsView
    case bookmarksView
    
}

extension DBManager {
    
    func setupDatabase (_ db: YapDatabase) {
        
        db.registerCodableSerialization(Feed.self, metadata: FeedMeta.self, forCollection: .feeds)
        
        db.registerCodableSerialization(Folder.self, forCollection: .folders)
        
        db.registerCodableSerialization(User.self, forCollection: .user)
        
        db.registerCodableSerialization(Article.self, metadata: ArticleMeta.self, forCollection: .articles)
        
        // Setting these causes the serializer to fail.
//        db.registerCodableSerialization(String.self, forCollection: .sync)
//        db.registerCodableSerialization(String.self, forCollection: .localNames)
    
        db.registerCodableSerialization([Content].self, forCollection: .articlesContent)
        db.registerCodableSerialization([Content].self, forCollection: .articlesFulltext)
        
    }
    
    func setupViews(_ db: YapDatabase) {
        
        do {
            
            let group = YapDatabaseViewGrouping.withKeyBlock { (t, collection, key) -> String? in
                
                switch collection {
                case CollectionNames.articles.rawValue:
                    return GroupNames.articles.rawValue
                case CollectionNames.feeds.rawValue:
                    return GroupNames.feeds.rawValue
                case CollectionNames.folders.rawValue:
                    return GroupNames.folders.rawValue
                default:
                    return nil
                }
                
            }
            
            let sort = YapDatabaseViewSorting.withObjectBlock { (t, group, c1, k1, o1, c2: String?, k2: String?, o2: Any?) -> ComparisonResult in

                if group == GroupNames.feeds.rawValue {

                    guard let f1 = o1 as? Feed, let f2 = o2 as? Feed else {
                        return .orderedSame
                    }

                    return f1.feedID.compare(other: f2.feedID)

                }
                else if group == GroupNames.folders.rawValue {

                    guard let f1 = o1 as? Folder, let f2 = o2 as? Folder else {
                        return .orderedSame
                    }

                    return f1.title.compare(f2.title)

                }
                else if group == GroupNames.articles.rawValue {

                    guard let a1 = o1 as? Article, let a2 = o2 as? Article else {
                        return .orderedSame
                    }

                    return a1.timestamp.compare(a2.timestamp)

                }

                return .orderedSame

            }
            
            let view = YapDatabaseAutoView(grouping: group, sorting: sort, versionTag: DB_VERSION_TAG)
            db.register(view, withName: .rootView)
            
        }
        
        // the following views only deal with articles so we limit the scope with a deny list.
        // using an allowList does not work as expected.
        let options = YapDatabaseViewOptions()
        
        let all = Set(CollectionNames.allCases).filter { $0 != .articles }
        
        let denyList = YapWhitelistBlacklist(blacklist: all)
        
        options.allowedCollections = denyList
        
        // Feeds View
        do {
            
            let grouping = YapDatabaseViewGrouping.withKeyBlock { (t, col, key) -> String? in
                
                if col == CollectionNames.articles.rawValue {
                    return GroupNames.articles.rawValue
                }
                
                return nil
                
            }
            
            let sorting = YapDatabaseViewSorting.withMetadataBlock { (t, group, c1, k1, m1, c2, k2, m2) -> ComparisonResult in
                
                guard let md1 = m1 as? ArticleMeta, let md2 = m2 as? ArticleMeta else {
                    return .orderedSame
                }
                
                // we reverse compare since we need the default sorting
                // to be latest first.
                return md2.timestamp.compare(other: md1.timestamp)
                
            }
            
            let view = YapDatabaseAutoView(grouping: grouping, sorting: sorting, versionTag: DB_VERSION_TAG)
            
            db.register(view, withName: .feedView)
            
            let filter = YapDatabaseViewFiltering.withMetadataBlock { [weak self] (t, g, c, k, m) -> Bool in
                
                guard c == CollectionNames.articles.rawValue else {
                    return false
                }
                
                guard let sself = self else {
                    return false
                }
                
                guard let metadata = m as? ArticleMeta else {
                    return false
                }
                
                guard let user = sself.user else {
                    return true
                }
                
                // Filters of the user
                guard user.filters.count > 0 else {
                    return true
                }
                
                // compare the title to each item in the filters
                let wordCloud = metadata.titleWordCloud ?? []
                
                let set1 = Set(wordCloud)
                let set2 = Set(user.filters)
                
                return set1.intersection(set2).count == 0
                
            }
            
            let articlesView = YapDatabaseFilteredView(parentViewName: DBManagerViews.feedView.rawValue, filtering: filter, versionTag: DB_VERSION_TAG)
            
            db.register(articlesView, withName: .articlesView)
            
        }
        
        // Unreads View
        do {
            
            let filter = YapDatabaseViewFiltering.withMetadataBlock { (t, g, c, k, m) -> Bool in
                
                guard c == CollectionNames.articles.rawValue else {
                    return false
                }
                
                guard let metadata = m as? ArticleMeta else {
                    return false
                }
                
                guard metadata.read == false else {
                    return false
                }
                
                // check date, should be within 14 days
                let timestamp = metadata.timestamp
                let now = Date().timeIntervalSince1970
                
                let diff = (now - timestamp)
                
                if diff < 0 {
                    // future date
                    return true
                }
                
                return diff <= 1209600
                
            }
            
            let unreadsView = YapDatabaseFilteredView(parentViewName: DBManagerViews.articlesView.rawValue, filtering: filter, versionTag: DB_VERSION_TAG)
            
            db.register(unreadsView, withName: .unreadsView)
            
        }
        
        // Bookmarks
        do {
            
            let filtering = YapDatabaseViewFiltering.withMetadataBlock { (t, g, c, k, m) -> Bool in
                
                guard c == CollectionNames.articles.rawValue else {
                    return false
                }
                
                guard let metadata = m as? ArticleMeta else {
                    return false
                }
                
                return metadata.bookmarked == true
                
            }
            
            let bookmarksView = YapDatabaseFilteredView(parentViewName: DBManagerViews.articlesView.rawValue, filtering: filtering, versionTag: DB_VERSION_TAG)
            
            db.register(bookmarksView, withName: .bookmarksView)
            
        }
        
    }
    
}

// MARK - YapDatabase Extensions
extension YapDatabase {
    
    public func register(_ ext: YapDatabaseExtension, withName: DBManagerViews) {
        
        register(ext, withName: withName.rawValue)
        
    }
    
    public func registerCodableSerialization<O, M>(_ objectType: O.Type, metadata metadataType: M.Type, forCollection collection: CollectionNames) where O: Codable, M: Codable {
        
        self.registerCodableSerialization(objectType, metadata: metadataType, forCollection: collection.rawValue)
        
    }
    
    public func registerCodableSerialization<T>(_ type: T.Type, forCollection collection: CollectionNames) where T: Codable {
        
        self.registerCodableSerialization(type, forCollection: collection.rawValue)
        
    }
    
    public func view<R: Any>(for name:DBManagerViews, extensionType: R) -> R? {
        
        return registeredExtension(name.rawValue) as? R
        
    }
    
}

extension YapDatabaseReadTransaction {
    
    // GET
    
    func object(forKey: String, inCollection: CollectionNames) -> Any? {
        
        return object(forKey: forKey, inCollection: inCollection.rawValue)
        
    }
    
    func metadata(forKey: String, inCollection: CollectionNames) -> Any? {
        
        return metadata(forKey: forKey, inCollection: inCollection.rawValue)
        
    }
    
    func allKeys(inCollection collection: CollectionNames) -> [String] {
        
        allKeys(inCollection: collection.rawValue)
        
    }
    
    func ext(_ extensionName: DBManagerViews) -> YapDatabaseExtensionTransaction? {
        
        return ext(extensionName.rawValue)
        
    }
    
}

extension YapDatabaseReadWriteTransaction {
    
    // ADD
    func setObject(_ obj: Any, forKey: String, inCollection: CollectionNames) {
        
        setObject(obj, forKey: forKey, inCollection: inCollection.rawValue)
        
    }
    
    func setObject(_ obj: Any, forKey: String, inCollection: CollectionNames, withMetadata: Any?) {
        
        setObject(obj, forKey: forKey, inCollection: inCollection.rawValue, withMetadata: withMetadata)
        
    }
    
    // DELETE
    
    func removeObject(forKey: String, inCollection: CollectionNames) {
        
        removeObject(forKey: forKey, inCollection: inCollection.rawValue)
        
    }
    
    func removeObjects(forKeys: [String], inCollection: CollectionNames) {
        
        removeObjects(forKeys: forKeys, inCollection: inCollection.rawValue)
        
    }
    
    func removeAllObjects(inCollection: CollectionNames) {
        
        removeAllObjects(inCollection: inCollection.rawValue)
        
    }
    
}
