#import <DZKit/DZObject.h>
#import "Range.h"

@interface Content : DZObject <NSCoding> {

}

@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSArray <Range *> * ranges;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *alt;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSNumber *level;
@property (nonatomic, strong) NSArray <Content *> *items;
@property (nonatomic, strong) NSDictionary *attributes;

+ (Content *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
