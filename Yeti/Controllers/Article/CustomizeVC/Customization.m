//
//  Customization.m
//  Yeti
//
//  Created by Nikhil Nigade on 12/02/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "Customization.h"
#import "PrefsManager.h"

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
        
        _name = name;
        _displayName = displayName;
        
        // check if the defaults have an existing value.
        NSNumber *value = [SharedPrefs.defaults valueForKey:self.name];
        
        if (value != nil) {

            NSLogDebug(@"Found exisiting value for %@: %@", self.name, value);
            
            _value = value;
        }
        
    }
    
    return self;
    
}

#pragma mark - Setters

- (void)setValue:(NSNumber *)value {
    
    _value = value;
    
    [SharedPrefs setValue:_value forKey:self.name];
    
}

@end
