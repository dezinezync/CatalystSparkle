
#import <DZKit/DZObject.h>
#import <DZKit/DZDatasourceModel.h>
#import "NSPointerArray+AbstractionHelpers.h"

@class Feed;

@interface Folder : DZObject <NSSecureCoding, NSCopying, DZDatasourceModel> {

}

@property (nonatomic, copy) NSString *created;
// weakly references Feed objects
@property (nonatomic, strong) NSPointerArray *feeds;
@property (nonatomic, copy) NSNumber *folderID;
@property (nonatomic, copy) NSString *modified;
@property (nonatomic, copy) NSNumber *status;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSNumber *userID;

@property (nonatomic, strong) NSSet <NSNumber *> *feedIDs;

@property (atomic, assign, getter=isExpanded) BOOL expanded;

+ (Folder *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

- (BOOL)isEqualToFolder:(Folder *)folder;

@property (nonatomic, readonly) NSNumber *unreadCount;

@end
