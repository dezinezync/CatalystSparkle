#import <DZKit/DZObject.h>

@class Enclosure;

@interface FeedItem : DZObject <NSSecureCoding, NSCopying> {

}

#pragma mark - Properties from server or DB

@property (nonatomic, copy) NSNumber *identifier;
@property (nonatomic, copy) NSString *articleTitle;
@property (nonatomic, copy) NSString *articleURL;
@property (nonatomic, copy) NSString *author;
@property (nonatomic, copy) NSString *blogTitle;
@property (nonatomic, assign, getter=isBookmarked) BOOL bookmarked;
@property (nonatomic, copy) NSArray *content;
@property (nonatomic, copy) NSString *coverImage;
@property (nonatomic, copy) NSString *guid;
@property (nonatomic, copy) NSString *modified;
@property (nonatomic, assign, getter=isRead) BOOL read;
@property (nonatomic, copy) NSDate *timestamp;

@property (nonatomic, copy) NSString *itunesImage;
@property (nonatomic, copy) NSString *mediaDescription;
@property (nonatomic, copy) NSString *mediaRating;
@property (nonatomic, copy) NSString *mediaCredit;

@property (nonatomic, strong) NSArray <Enclosure *> *enclosures;

@property (nonatomic, copy) NSNumber *feedID;
@property (nonatomic, copy) NSString *summary;

@property (nonatomic, assign) BOOL mercury;

/// Applicable for micor-blog content only
@property (nonatomic, strong) NSString *textFromContent;

// used for encoding and decoding
@property (class, nonatomic, strong) NSDateFormatter *formatter;

+ (FeedItem *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (BOOL)isEqualToItem:(FeedItem *)item;

- (NSDictionary *)dictionaryRepresentation;

- (NSComparisonResult)compare:(FeedItem *)item;

- (NSItemProvider * _Nullable)itemProvider;

@end
