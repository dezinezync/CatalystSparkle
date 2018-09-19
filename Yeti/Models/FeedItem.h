#import <DZKit/DZObject.h>
#import "Enclosure.h"
#import <DZKit/DZDatasourceModel.h>

#ifdef SHARE_EXTENSION
#import <UIKit/UIKit.h>
#endif

@interface FeedItem : DZObject <NSCoding, NSCopying, DZDatasourceModel> {

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

//@property (nonatomic, strong) NSArray <NSString *> *keywords;
//@property (nonatomic, strong) NSArray <Enclosure *> *enclosures;

@property (nonatomic, copy) NSNumber *feedID;
@property (nonatomic, copy) NSString *summary;

// used for encoding and decoding
@property (class, nonatomic, strong) NSDateFormatter *formatter;

+ (FeedItem *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

- (NSComparisonResult)compare:(FeedItem *)item;

@end
