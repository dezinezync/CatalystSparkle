#import "MetaOpenGraph.h"

@interface FeedMeta : DZObject <NSSecureCoding> {

}

@property (nonatomic, strong) NSDictionary *icons;
//@property (nonatomic, copy) NSString *descriptionText;
//@property (nonatomic, copy) NSArray *feedlinks;
//@property (nonatomic, copy) NSArray *feeds;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, copy) NSArray *keywords;
@property (nonatomic, strong) MetaOpenGraph *opengraph;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *url;

+ (FeedMeta *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
