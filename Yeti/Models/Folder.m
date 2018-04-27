#import "Folder.h"
#import "Feed.h"

@implementation Folder

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.created forKey:@"created"];
    [encoder encodeObject:self.feeds forKey:@"feeds"];
    [encoder encodeObject:self.folderID forKey:@"folderID"];
    [encoder encodeObject:self.modified forKey:@"modified"];
    [encoder encodeObject:self.status forKey:@"status"];
    [encoder encodeObject:self.title forKey:@"title"];
    [encoder encodeObject:self.userID forKey:@"userID"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder])) {
        self.created = [decoder decodeObjectForKey:@"created"];
        self.feeds = [decoder decodeObjectForKey:@"feeds"];
        self.folderID = [decoder decodeObjectForKey:@"folderID"];
        self.modified = [decoder decodeObjectForKey:@"modified"];
        self.status = [decoder decodeObjectForKey:@"status"];
        self.title = [decoder decodeObjectForKey:@"title"];
        self.userID = [decoder decodeObjectForKey:@"userID"];
    }
    return self;
}

- (instancetype)copy {
    Folder *instance = [Folder instanceFromDictionary:self.dictionaryRepresentation];
    
    return instance;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return [self copy];
}

+ (Folder *)instanceFromDictionary:(NSDictionary *)aDictionary
{

    Folder *instance = [[Folder alloc] init];
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

    if ([key isEqualToString:@"feeds"]) {

        if ([value isKindOfClass:[NSArray class]])
{

            NSMutableArray *myMembers = [NSMutableArray arrayWithCapacity:[value count]];
            for (id valueMember in value) {
                [myMembers addObject:valueMember];
            }

            self.feeds = myMembers;

        }

    } else {
        [super setValue:value forKey:key];
    }

}


- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{

    if ([key isEqualToString:@"id"]) {
        [self setValue:value forKey:@"folderID"];
    } else {
//        [super setValue:value forUndefinedKey:key];
    }

}


- (NSDictionary *)dictionaryRepresentation
{

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    if (self.created) {
        [dictionary setObject:self.created forKey:@"created"];
    }

    if (self.feeds) {
        
        if ([self.feeds count] && [[self.feeds objectAtIndex:0] isKindOfClass:Folder.class]) {
            
            NSMutableArray *members = [NSMutableArray arrayWithCapacity:self.feeds.count];
            
            [self.feeds enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [members addObject:[(Feed *)obj dictionaryRepresentation]];
            }];
            
            [dictionary setObject:members forKey:@"feeds"];
        }
        else {
            [dictionary setObject:self.feeds forKey:@"feeds"];
        }
        
    }

    if (self.folderID) {
        [dictionary setObject:self.folderID forKey:@"folderID"];
    }

    if (self.modified) {
        [dictionary setObject:self.modified forKey:@"modified"];
    }

    if (self.status) {
        [dictionary setObject:self.status forKey:@"status"];
    }

    if (self.title) {
        [dictionary setObject:self.title forKey:@"title"];
    }

    if (self.userID) {
        [dictionary setObject:self.userID forKey:@"userID"];
    }

    return dictionary;

}


@end