#import <DZKit/DZObject.h>


@interface MetaOpenGraph : DZObject <NSSecureCoding> {

}

//@property (nonatomic, copy) NSString *descriptionText;
@property (nonatomic, copy) NSString *image;
@property (nonatomic, copy) NSString *locale;
//@property (nonatomic, copy) NSString *title;
//@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *url;

+ (MetaOpenGraph *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
