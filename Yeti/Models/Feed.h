#import <DZKit/DZCloudObject.h>

#import "FeedItem.h"
#import "Author.h"

#import <DZKit/DZDatasourceModel.h>

@interface Feed : DZCloudObject <NSCoding, DZDatasourceModel> {

}

@property (nonatomic, copy) NSString *etag;
@property (nonatomic, copy) NSNumber *feedID;
@property (nonatomic, copy) NSString *folder;
@property (nonatomic, copy) NSArray <FeedItem *> *articles;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *favicon;
@property (nonatomic, strong) NSDictionary *extra;
@property (nonatomic, copy) NSNumber *unread;

@property (nonatomic, strong) NSArray <Author *> *authors;

+ (Feed *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

- (NSString *)faviconURI;

@end
