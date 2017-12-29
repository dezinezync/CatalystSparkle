#import <DZKit/DZObject.h>
#import "Enclosure.h"
#import <DZKit/DZDatasourceModel.h>

@interface FeedItem : DZObject <NSCoding, DZDatasourceModel> {

}

@property (nonatomic, strong) NSArray <UIView *> *primedContent;

#pragma mark - Properties from server or DB

@property (nonatomic, copy) NSNumber *identifier;
@property (nonatomic, copy) NSString *articleTitle;
@property (nonatomic, copy) NSString *articleURL;
@property (nonatomic, copy) NSString *author;
@property (nonatomic, copy) NSString *blogTitle;
@property (nonatomic, assign) BOOL bookmarked;
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

@property (nonatomic, strong) NSArray <NSString *> *keywords;
@property (nonatomic, strong) NSArray <Enclosure *> *enclosures;

@property (nonatomic, copy) NSNumber *feedID;
@property (nonatomic, copy) NSString *summary;

+ (FeedItem *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
