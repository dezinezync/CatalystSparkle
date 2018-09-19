
#import <DZKit/DZObject.h>
#import <DZKit/DZDatasourceModel.h>
#import "NSPointerArray+AbstractionHelpers.h"

@class Feed;

@interface Folder : DZObject <NSCoding, NSCopying, DZDatasourceModel> {

}

@property (nonatomic, copy) NSString *created;
// weakly references Feed objects
@property (nonatomic, strong) NSPointerArray *feeds;
@property (nonatomic, copy) NSNumber *folderID;
@property (nonatomic, copy) NSString *modified;
@property (nonatomic, copy) NSNumber *status;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSNumber *userID;

@property (nonatomic, assign, getter=isExpanded) BOOL expanded;

+ (Folder *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@property (nonatomic, readonly) NSNumber *unreadCount;

@end
