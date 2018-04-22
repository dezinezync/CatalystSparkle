
#import <DZKit/DZCloudObject.h>

@interface Folder : DZCloudObject <NSCoding, NSCopying> {

}

@property (nonatomic, copy) NSString *created;
@property (nonatomic, copy) NSArray *feeds;
@property (nonatomic, copy) NSNumber *folderID;
@property (nonatomic, copy) NSString *modified;
@property (nonatomic, copy) NSNumber *status;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSNumber *userID;

@property (nonatomic, assign, getter=isExpanded) BOOL expanded;

+ (Folder *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
