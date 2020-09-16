//
//  VideoInfo.m
//  Yeti
//
//  Created by Nikhil Nigade on 06/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#ifndef propSel
    #define propSel(sel) NSStringFromSelector(@selector(sel))
#endif

#ifndef formattedString
    #define formattedString(fmt,...) [[NSString alloc] initWithFormat:fmt, ##__VA_ARGS__]
#endif

#import "VideoInfo.h"

@implementation VideoInfo

- (NSDictionary *)dictionaryRepresentation {
    
    NSMutableDictionary *dict = @{}.mutableCopy;
    
    if (self.url) {
        [dict setValue:self.url forKey:propSel(url)];
    }
    
    if (self.coverImage) {
        [dict setValue:self.coverImage forKey:propSel(coverImage)];
    }
    
    return dict.copy;
    
}

- (NSString *)description {
    NSString *desc = [super description];
    
    return formattedString(@"%@ %@", desc, self.dictionaryRepresentation);
}

@end
