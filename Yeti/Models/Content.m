#import "Content.h"
#import <DZKit/NSArray+RZArrayCandy.h>

@implementation Content
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.content forKey:@"content"];
    [encoder encodeObject:self.ranges forKey:@"ranges"];
    [encoder encodeObject:self.type forKey:@"type"];
    [encoder encodeObject:self.alt forKey:@"alt"];
    [encoder encodeObject:self.url forKey:@"url"];
    [encoder encodeObject:self.identifier forKey:@"identifier"];
    [encoder encodeObject:self.level forKey:@"level"];
    [encoder encodeObject:self.items forKey:@"items"];
    [encoder encodeObject:self.attributes forKey:@"attributes"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder])) {
        self.content = [decoder decodeObjectForKey:@"content"];
        self.ranges = [decoder decodeObjectForKey:@"ranges"];
        self.type = [decoder decodeObjectForKey:@"type"];
        self.identifier = [decoder decodeObjectForKey:@"identifier"];
        self.alt = [decoder decodeObjectForKey:@"alt"];
        self.url = [decoder decodeObjectForKey:@"url"];
        self.items = [decoder decodeObjectForKey:@"items"];
        self.level = [decoder decodeObjectForKey:@"level"];
        self.attributes = [decoder decodeObjectForKey:@"attributes"];
    }
    return self;
}

+ (Content *)instanceFromDictionary:(NSDictionary *)aDictionary
{

    Content *instance = [[Content alloc] init];
    [instance setAttributesFromDictionary:aDictionary];
    return instance;

}

- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary
{

    if (![aDictionary isKindOfClass:[NSDictionary class]]) {
        return;
    }

    [self setValuesForKeysWithDictionary:aDictionary];

}

- (void)setValue:(id)value forKey:(NSString *)key
{

    if ([key isEqualToString:@"ranges"]) {

        if ([value isKindOfClass:[NSArray class]])
        {

            NSMutableArray *myMembers = [NSMutableArray arrayWithCapacity:[value count]];
            for (id valueMember in value) {
                if ([valueMember isKindOfClass:NSDictionary.class])
                    [myMembers addObject:[Range instanceFromDictionary:valueMember]];
                else
                    [myMembers addObject:valueMember];
            }

            self.ranges = myMembers;

        }

    }
    else if ([key isEqualToString:@"items"] && [value isKindOfClass:NSArray.class]) {
        
        NSArray <Content *> *items = [value rz_map:^id(NSDictionary *obj, NSUInteger idx, NSArray *array) {
            return [Content instanceFromDictionary:obj];
        }];
        
        [super setValue:items forKey:key];
        
    }
    else {
        [super setValue:value forKey:key];
    }

}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    DDLogWarn(@"%@ : %@-%@", NSStringFromClass(self.class), key, value);
}


- (NSDictionary *)dictionaryRepresentation
{

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    if (self.content) {
        [dictionary setObject:self.content forKey:@"content"];
    }

    if (self.ranges) {
        
        NSArray <NSDictionary *> *ranges = [self.ranges rz_map:^id(Range *obj, NSUInteger idx, NSArray *array) {
            return obj.dictionaryRepresentation;
        }];
        
        [dictionary setObject:ranges forKey:@"ranges"];
    }

    if (self.type) {
        [dictionary setObject:self.type forKey:@"type"];
    }
    
    if (self.alt) {
        [dictionary setObject:self.alt forKey:@"alt"];
    }
    
    if (self.identifier) {
        [dictionary setObject:self.identifier forKey:@"identifier"];
    }
    
    if (self.url) {
        [dictionary setObject:self.url forKey:@"url"];
    }
    
    if (self.level) {
        [dictionary setObject:self.level forKey:@"level"];
    }
    
    if (self.items) {
        
        NSArray <NSDictionary *> *items = [self.items rz_map:^id(Content *obj, NSUInteger idx, NSArray *array) {
            return obj.dictionaryRepresentation;
        }];
        
        [dictionary setObject:items forKey:@"items"];
    }
    
    if (self.attributes) {
        [dictionary setObject:self.attributes forKey:@"attributes"];
    }

    return dictionary;

}


@end
