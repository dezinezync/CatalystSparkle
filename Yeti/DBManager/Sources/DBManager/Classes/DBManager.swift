import Foundation
import YapDatabase
import Models
import Combine

/// Have the changes been fully synced with our local store?
private let SYNCED_CHANGES = "syncedChanges"

internal enum CollectionNames: String, CaseIterable {
    
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

private let DB_VERSION_TAG = "2020-12-23 10:20AM IST"

extension NSNotification.Name {
    static let YapDatabaseModifiedNotification = NSNotification.Name("YapDatabaseModifiedNotification")
    static let DBManagerDidUpdate = Notification.Name("DBManagerDidUpdate")
}

public let titleWordCloudKey = "titleWordCloud"

public let notificationsKey = "notifications"

public final class DBManager {
    
    public static let shared = DBManager()
    
    public init() {
        
        setupNotifications()
        
    }
    
    // MARK: - DB & Connections
    public lazy var database: YapDatabase = {
        
        let fm = FileManager.default
        #if DEBUG
        let dbName = "elytra-debug.sqlite"
        #else
        let dbName = "elytra.sqlite"
        #endif
        
        guard let baseURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("DB Path could not be constructed")
        }
        
        let dbURL = baseURL.appendingPathComponent(dbName, isDirectory: false)
        
        guard let db = YapDatabase(url: dbURL) else {
            fatalError("Could not open DB")
        }
        
        setupDatabase(db)
        
        return db
    }()
    
    public lazy var uiConnection: YapDatabaseConnection = {
        
        var c = database.newConnection()
        
        c.enableExceptionsForImplicitlyEndingLongLivedReadTransaction()
        c.beginLongLivedReadTransaction()
        
        return c
        
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
    fileprivate var cancellables = [AnyCancellable]()
    
    internal func setupNotifications() {
        
        NotificationCenter.default.publisher(for: .YapDatabaseModifiedNotification)
            .subscribe(on: readQueue)
            .sink { [weak self] (note) in
                
                guard let sself = self else {
                    return
                }
                
                // Move connections to the latest commit
                let notes = sself.uiConnection.beginLongLivedReadTransaction()
                let notes2 = sself.countsConnection.beginLongLivedReadTransaction()
                
                var uniqueNotes = Set(arrayLiteral: notes)
                uniqueNotes = uniqueNotes.union(Set(arrayLiteral: notes2))
                
                let notifications = uniqueNotes.map { $0 }
                
                if notifications.count == 0 {
                    // nothing changed.
                    return
                }
                
                // Notify our observors
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .DBManagerDidUpdate, object: self, userInfo: [notificationsKey: notifications])
                }
                
                // @TODO: Update unread counters
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
                
                self._user = u
                
                return self._user
            }
            
            return _user
            
        }
        
        set {
            
            _user = newValue
            setUser(newValue, completion: nil)
            
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
    fileprivate var _feeds = [Feed]()
    
    public var feeds: [Feed] {
        
        get {
            
            guard _feeds.count == 0 else {
                return _feeds
            }
            
            var f = [Feed]()
            
            readQueue.async { [weak self] in
                
                self?.uiConnection.read({ (t) in
                    
                    let keys = t.allKeys(inCollection: .feeds)
                    
                    if keys.count == 0 {
                        return;
                    }
                    
                    for k in keys {
                        
                        let feed = t.object(forKey: k, inCollection: .feeds) as! Feed
                        
                        f.append(feed)
                        
                    }
                    
                })
                
            }
            
            _feeds = f
            
            return _feeds
            
        }
        
        set {
            
            if newValue.count == 0 {
                return
            }
            
            _feeds = newValue
            
            writeQueue.sync { [weak self] in
                
                self?.bgConnection.readWrite({ (t) in
                    
                    for f in newValue {
                        
                        let key = "\(f.feedID!)"
                        
                        let metadata = self?.metadataForFeed(f)
                        
                        t.setObject(f, forKey: key, inCollection: .feeds, withMetadata: metadata)
                        
                    }
                    
                })
                
                _preSyncFeedMetadata = [UInt: FeedMeta]()
                
            }
            
        }
        
    }
    
    public func feed(for id: UInt) -> Feed? {
        
        return _feeds.first { $0.feedID == id }
        
    }
    
    fileprivate var _preSyncFeedMetadata = [UInt: FeedMeta]()
    
    fileprivate func _metadataForFeed(_ feed: Feed) -> FeedMeta {
        
        var existing: FeedMeta! = nil
        
        if _preSyncFeedMetadata.count != 0,
           let item = _preSyncFeedMetadata[feed.feedID] {
            
            existing = item
            
        }
        else {
            
            if feed.feedID != nil && feed.url != nil {
                
                var m = FeedMeta(id: feed.feedID, url: feed.url, title: feed.title)
                
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
        
        writeQueue.async { [weak self] in
            
            let key = "\(feed.feedID!)"
            
            self?.bgConnection.asyncReadWrite({ (t) in
                
                t.setObject(feed, forKey: key, inCollection: .feeds, withMetadata: metadata)
                
            })
            
        }
        
    }
    
    public func feedForID(_ id: UInt) -> Feed? {
        
        return feeds.first { $0.feedID == id }
        
    }
    
    // @TODO: FeedBulkOperation
    
    // @TODO: Custom Feed Names
    
    // MARK: - Folders
    fileprivate var _folders = [Folder]()
    
    public var folders: [Folder] {
        
        get {
            
            guard _folders.count != 0 else {
                return _folders
            }
            
            var f = [Folder]()
            
            uiConnection.read { [weak self] (t) in
                
                let keys = t.allKeys(inCollection: .folders)
                
                for k in keys {
                    
                    let folder = t.object(forKey: k, inCollection: .folders) as! Folder
                    
                    if folder.feedIDs.count > 0 {
                        
                        for id in folder.feedIDs {
                            
                            if let feed = self?.feedForID(id) {
                                
                                folder.feeds.append { () -> Feed? in
                                    return feed
                                }
                                
                                feed.folderID = folder.folderID
                                
                            }
                            
                        }
                        
                    }
                    
                    f.append(folder)
                    
                }
                
            }
            
            _folders = f
            
            return _folders
            
        }
        
        set {
            
            _folders = newValue
            
            guard newValue.count > 0 else {
                return
            }
            
            writeQueue.async { [weak self] in
                
                self?.bgConnection.asyncReadWrite { (t) in
                    
                    for folder in newValue {
                        
                        let copy = folder.copy() as! Folder
                        copy.feeds = []
                        
                        t.setObject(copy, forKey: "\(copy.folderID!)", inCollection: .folders)
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    // MARK: - Articles
    
    public func article(for id: UInt, feedID: UInt) -> Article? {
        
        var a: Article! = nil
        
        uiConnection.read { (t) in
            
            a = t.object(forKey: "\(id)", inCollection: .articles) as? Article
            
        }
        
        return a
        
    }
    
    public func content(for articleID: UInt) -> [Content]? {
        
        var c: [Content]! = nil
        
        uiConnection.read { (t) in
            
            c = t.object(forKey: "\(articleID)", inCollection: .articlesContent) as? [Content]
            
        }
        
        return c
        
    }
    
    public func fullText(for articleID: UInt) -> [Content]? {
        
        var c: [Content]! = nil
        
        uiConnection.read { (t) in
            
            c = t.object(forKey: "\(articleID)", inCollection: .articlesFulltext) as? [Content]
            
        }
        
        return c
        
    }
    
    public func add (article: Article) {
        
        add(articles: [article], strip: true)
        
    }
    
    public func add(article: Article, strip: Bool) {
        
        guard article.identifier != nil, article.feedID != nil else {
            fatalError("Error adding article with no identifer or feed ID to the database.")
        }
        
        add(articles: [article], strip: strip)
        
    }
    
    public func add(articles: [Article], strip: Bool) {
        
        guard articles.count > 0 else {
            return
        }
        
        let now = Date()
        
        writeQueue.sync {
            
            bgConnection.asyncReadWrite { (t) in
                
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
                    
                    t.setObject(a.content, forKey: "\(a.identifier!)", inCollection: .articlesContent)
                    
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
                    
                    let metadata = ArticleMeta(feedID: a.feedID, read: a.read, bookmarked: a.bookmarked, fulltext: a.fulltext, timestamp: a.timestamp, titleWordCloud: components)
                    
                    t.setObject(a, forKey: "\(a.identifier!)", inCollection: .articles, withMetadata: metadata)
                    
                }
                
            }
            
        }
        
    }
    
    public func add (fullText: [Content], articleID: UInt) {
        
        guard fullText.count != 0 else {
            return
        }
        
        writeQueue.sync {
            
            bgConnection.asyncReadWrite { (t) in
                
                t.setObject(fullText, forKey: "\(articleID)", inCollection: .articlesFulltext)
                
            }
            
        }
        
    }
    
    public func delete(fullTextFor articleID: UInt) {
        
        writeQueue.sync {
            
            bgConnection.asyncReadWrite { (t) in
                
                t.removeObject(forKey: "\(articleID)", inCollection: .articlesFulltext)
                
            }
            
        }
        
    }
    
    public func delete(article: Article) {
        
        _delete(articleID: article.identifier)
        
    }
    
    fileprivate func _delete(articleID: UInt) {
        
        writeQueue.sync { [weak self] in
            
            self?.bgConnection.asyncReadWrite({ (t) in
                
                let key = "\(articleID)"
                
                self?._delete(articleID: key, transaction: t)
                
            })
            
        }
        
    }
    
    fileprivate func _delete(articleID: String, transaction: YapDatabaseReadWriteTransaction) {
        
        transaction.removeObject(forKey: articleID, inCollection: .articles)
        transaction.removeObject(forKey: articleID, inCollection: .articlesContent)
        transaction.removeObject(forKey: articleID, inCollection: .articlesFulltext)
        
    }
    
    public func delete(allArticlesFor feed: Feed) {
        
        writeQueue.async { [weak self] in
            
            let col = "\(CollectionNames.articles.rawValue):\(feed.feedID!)"
            
            self?.bgConnection.asyncReadWrite({ (t) in
                
                let keys = t.allKeys(inCollection: col)
                
                t.removeAllObjects(inCollection: col)
                
                t.removeObjects(forKeys: keys, inCollection: .articlesContent)
                
                t.removeObjects(forKeys: keys, inCollection: .articlesFulltext)
                
                t.removeObject(forKey: "\(feed.feedID!)", inCollection: .feeds)
                
            })
            
        }
        
    }
    
}

// MARK: - Bulk Operations
extension DBManager {
    
    public func purgeDataForResync () {
     
        purgeFeedsForResync()
        
        bgConnection.asyncReadWrite { (transaction) in
            
            transaction.removeAllObjects(inCollection: .articlesContent)
            transaction.removeAllObjects(inCollection: .articlesFulltext)
            
            transaction.removeAllObjects(inCollection: .articles)
            transaction.removeAllObjects(inCollection: .sync)
            
        }
        
    }
    
    public func purgeFeedsForResync () {
        
        // @TODO: Persist Feed metadata
        
        bgConnection.asyncReadWrite { (transaction) in
            
            transaction.removeAllObjects(inCollection: .feeds)
            transaction.removeAllObjects(inCollection: .folders)
            
        }
        
    }
    
}

// MARK: - DB Registrations
extension DBManager {
    
    func setupDatabase (_ db: YapDatabase) {
        
        db.registerCodableSerialization(Feed.self, metadata: FeedMeta.self, forCollection: CollectionNames.feeds.rawValue)
        
        db.registerCodableSerialization(Folder.self, forCollection: CollectionNames.folders.rawValue)
        
        db.registerCodableSerialization(User.self, forCollection: CollectionNames.folders.rawValue)
        
        db.registerCodableSerialization(Article.self, metadata: ArticleMeta.self, forCollection: CollectionNames.articles.rawValue)
        
        db.registerCodableSerialization(String.self, forCollection: CollectionNames.sync.rawValue)
        db.registerCodableSerialization(String.self, forCollection: CollectionNames.localNames.rawValue)
    
        db.registerCodableSerialization(Content.self, forCollection: CollectionNames.articlesContent.rawValue)
        db.registerCodableSerialization(Content.self, forCollection: CollectionNames.articlesFulltext.rawValue)
        
        db.registerCodableSerialization(User.self, forCollection: CollectionNames.user.rawValue)
        
    }
    
}

extension YapDatabaseReadTransaction {
    
    // GET
    
    func object(forKey: String, inCollection: CollectionNames) -> Any? {
        
        return object(forKey: forKey, inCollection: inCollection.rawValue)
        
    }
    
    func allKeys(inCollection: CollectionNames) -> [String] {
        
        return allKeys(inCollection: inCollection.rawValue)
        
    }
    
    func metadata(forKey: String, inCollection: CollectionNames) -> Any? {
        
        return metadata(forKey: forKey, inCollection: inCollection.rawValue)
        
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
