#import <DZKit/DZObject.h>

#import "FeedItem.h"
#import "Author.h"
#import "FeedMeta.h"
#import "UnreadCountObservor.h"
#import "Folder.h"

@interface Feed : DZObject <NSSecureCoding, NSCopying> {
@public
    // ivar used when counting unreads to sync to the main property.
    NSUInteger _countingUnread;
}

@property (nonatomic, weak) id<UnreadCountObservor> unreadCountObservor;
@property (nonatomic, weak) id<UnreadCountObservor> unreadCountTitleObservor;

@property (nonatomic, copy) NSString *etag;
@property (nonatomic, copy) NSNumber *feedID;
@property (nonatomic, weak) Folder *folder;
//@property (nonatomic, copy) NSArray <FeedItem *> *articles;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *favicon;
@property (nonatomic, strong) FeedMeta *extra;
@property (nonatomic, copy) NSNumber *unread;
@property (nonatomic, copy) NSNumber *rpcCount;
@property (nonatomic, copy) NSDate *lastRPC;

@property (nonatomic, strong) UIImage *faviconImage;

@property (nonatomic, strong) NSArray <Author *> *authors;

@property (nonatomic, copy) NSString *hub;
@property (nonatomic, assign, getter=isHubSubscribed) BOOL hubSubscribed; // if the hub is subscribed, the push notifications are possible.
@property (nonatomic, assign, getter=isSubscribed) BOOL subscribed; // this indicates if the user is subscribed for push notifications.

@property (nonatomic, copy) NSNumber *folderID; // this is never copied or exposed. 

+ (Feed *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

- (BOOL)isEqualToFeed:(Feed *)object;

@property (nonatomic, strong) NSString *faviconURI;
@property (nonatomic) NSString *displayTitle;

@property (nonatomic, strong) NSString *localName;

- (BOOL)canShowExtraShareLevel;

@end
