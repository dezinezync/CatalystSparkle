#import <DZKit/DZObject.h>
#import <DZKit/DZDatasourceModel.h>

@interface Range : DZObject <NSCoding, DZDatasourceModel> {

}

@property (nonatomic, copy) NSString *element;
@property (nonatomic, assign) NSRange range;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSNumber *level;

+ (Range *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
