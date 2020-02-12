//
//  Customization.m
//  Yeti
//
//  Created by Nikhil Nigade on 12/02/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "Customization.h"

NSErrorDomain CustomizationDomain = @"com.elytra.errorDomain.customization";

@implementation Customization

- (instancetype)init {
    
    return [self initWithName:@"" displayName:@""];
    
}

- (instancetype)initWithName:(NSString * _Nonnull)name displayName:(NSString * _Nonnull)displayName {
    
    if (name == nil || [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
        @throw [NSError errorWithDomain:CustomizationDomain code:500 userInfo:@{NSLocalizedDescriptionKey: @"A name is required to initialize a Customization Model"}];
    }
    
    if (self = [super init]) {
        
        self.name = name;
        self.displayName = displayName;
        
        // check if the defaults have an existing value.
        NSNumber *value = [[NSUserDefaults standardUserDefaults] valueForKey:self.defaultsKey];
        
        if (value != nil) {
            
#ifdef DEBUG
            NSLog(@"Found exisiting value for %@: %@", self.name, value);
#endif
            
            self.value = value;
        }
        
    }
    
    return self;
    
}

#pragma mark - Getters

- (NSString *)defaultsKey {
    
    return [NSString stringWithFormat:@"elytra.customization.%@", self.name];
    
}

#pragma mark - Setters

- (void)setValue:(NSNumber *)value {
    
    _value = value;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (value == nil) {
        [defaults removeObjectForKey:self.defaultsKey];
    }
    else {
        [defaults setValue:value forKey:self.defaultsKey];
    }
    
    [defaults synchronize];
    
}

@end
