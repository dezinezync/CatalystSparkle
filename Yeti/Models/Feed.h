#import <DZKit/DZCloudObject.h>

#import "FeedItem.h"

@interface Feed : DZCloudObject <NSCoding> {

}

@property (nonatomic, copy) NSString *etag;
@property (nonatomic, copy) NSNumber *feedID;
@property (nonatomic, copy) NSString *folder;
@property (nonatomic, copy) NSArray <FeedItem *> *articles;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *favicon;

+ (Feed *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
