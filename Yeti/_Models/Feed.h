#import <DZKit/DZObject.h>

#import "FeedItem.h"
#import "Author.h"
#import "FeedMeta.h"
#import "UnreadCountObservor.h"
#import "Folder.h"

extern NSString * _Nonnull const kFeedSafariReaderMode;
extern NSString * _Nonnull const kFeedLocalNotifications;

@interface Feed : DZObject <NSSecureCoding, NSCopying> {
@public
    // ivar used when counting unreads to sync to the main property.
    NSUInteger _countingUnread;
}

@property (nonatomic, weak, nullable) id<UnreadCountObservor> unreadCountObservor;
@property (nonatomic, weak, nullable) id<UnreadCountObservor> unreadCountTitleObservor;

@property (nonatomic, copy) NSString * _Nullable etag;
@property (nonatomic, copy) NSNumber * _Nonnull feedID;
@property (nonatomic, weak) Folder * _Nullable folder;
//@property (nonatomic, copy) NSArray <FeedItem *> *articles;
@property (nonatomic, copy) NSString * _Nullable summary;
@property (nonatomic, copy) NSString * _Nullable title;
@property (nonatomic, copy) NSString * _Nonnull url;
@property (nonatomic, copy) NSString * _Nonnull favicon;
@property (nonatomic, strong) FeedMeta * _Nonnull extra;
@property (nonatomic, copy) NSNumber * _Nullable unread;
@property (nonatomic, copy) NSNumber * _Nullable rpcCount;
@property (nonatomic, copy) NSDate * _Nullable lastRPC;

@property (nonatomic, strong) UIImage * _Nullable faviconImage;

@property (nonatomic, strong) NSArray <Author *> * _Nullable authors;

@property (nonatomic, copy) NSString * _Nullable hub;
@property (nonatomic, assign, getter=isHubSubscribed) BOOL hubSubscribed; // if the hub is subscribed, the push notifications are possible.
@property (nonatomic, assign, getter=isSubscribed) BOOL subscribed; // this indicates if the user is subscribed for push notifications.

@property (nonatomic, copy) NSNumber * _Nullable folderID; // this is never copied or exposed.

+ (Feed * _Nonnull)instanceFromDictionary:(NSDictionary * _Nonnull)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary * _Nonnull)aDictionary;

- (NSDictionary * _Nonnull)dictionaryRepresentation;

- (BOOL)isEqualToFeed:(Feed * _Nullable)object;

@property (nonatomic, strong) NSString * _Nullable faviconURI;
@property (nonatomic) NSString * _Nonnull displayTitle;

@property (nonatomic, strong) NSString * _Nullable localName;

- (BOOL)canShowExtraShareLevel;

- (NSString * _Nullable)faviconProxyURIForSize:(CGFloat)size;

@end
