//
//  YTUserID.m
//  Yeti
//
//  Created by Nikhil Nigade on 26/12/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "YTUserID.h"
#import "FeedsManager.h"
#import <DZKit/AlertManager.h>

#import <DZTextKit/YetiConstants.h>
#import "Keychain.h"

NSString *const kAccountID = @"YTUserID";
NSString *const kUserID = @"userID";
NSString *const kUUIDString = @"UUIDString";

NSNotificationName const YTUserNotFound = @"com.yeti.note.userNotFound";

@interface YTUserID () {
    // how many attempts have we made since waiting.
    // max is 2. Starts with 0.
    // If we reach 2, create a new user.
    NSInteger _tries;
}

@end

@implementation YTUserID

- (instancetype)initWithDelegate:(id<YTUserDelegate>)delegate {
    if (self = [super init]) {
        
        self.delegate = delegate;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            id UUID = nil;
            
            UUID = self.UUIDString;
            
            NSNumber *userID = self.userID;
            
            NSLog(@"Initialised with: %@ %@", UUID, userID);
            
            if (UUID != nil && userID != nil) {
                [NSNotificationCenter.defaultCenter postNotificationName:UserDidUpdate object:nil];
                [MyDBManager setupSync];
            }
        });
        
    }
    
    return self;
}

- (void)setupAccountWithSuccess:(successBlock)successCB error:(errorBlock)errorCB {
    // check server
    if (self.delegate) {
        
        weakify(self);
        
        [self.delegate getUserInformation:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            strongify(self);
            
            NSDictionary *user = [responseObject valueForKey:@"user"];
#ifdef DEBUG
            NSLog(@"Got existing user: %@", user);
#endif
            self.userID = @([[user valueForKey:@"id"] integerValue]);
            
            if (@available(iOS 13, *)) {
                self.UUIDString = [user valueForKey:@"uuid"];
            }
            else {
                self.UUID = [[NSUUID alloc] initWithUUIDString:[user valueForKey:@"uuid"]];
            }
            
            if (successCB) {
                successCB(self, response, task);
            }
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            if ([error.localizedDescription containsString:@"pass a valid user"]) {
                
                return [self createNewUser:successCB errorBlock:errorCB];
                
            }
            
            if (errorCB) {
                errorCB(error, response, task);
            }
            
        }];
    }
    else {
        
        [self createNewUser:successCB errorBlock:errorCB];
    
    }
}

- (void)createNewUser:(successBlock)successCB errorBlock:(errorBlock)errorCB {
    
    self->_UUID = [NSUUID UUID];
    self.UUIDString = _UUID.UUIDString;
    
    // let our server know about these changes
    [self.delegate updateUserInformation:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
#ifdef DEBUG
        NSLog(@"created new user");
#endif
        NSDictionary *user = [responseObject valueForKey:@"user"];
        self.userID = @([[user valueForKey:@"id"] integerValue]);
#ifndef SHARE_EXTENSION
        [NSNotificationCenter.defaultCenter postNotificationName:UserDidUpdate object:nil];
#endif
        if (successCB) {
            successCB(self, response, task);
        }
        
    } error:errorCB];
    
}

#pragma mark -

- (NSString *)UUIDString {
    
    if (_UUIDString == nil) {
//#ifdef DEBUG
////        _UUIDString = @"815E2709-31CC-4EB8-9067-D84F224BED66";
//
//        _UUIDString = @"4CE0BC0B-82E6-4B08-84F5-DE5C56774064";
//#else
        NSError *error = nil;
        NSString *UUIDString = [Keychain stringFor:kUUIDString error:&error];
        
        if (error != nil) {
            NSLog(@"Error loading UUID String from Keychain: %@", error);
            
            UUIDString = [[NSUserDefaults standardUserDefaults] stringForKey:kUUIDString];
        }
        
        if (UUIDString == nil) {
            // if the UUID String is still nil at this point
            // the UUID has not been migrated
            UUIDString = [Keychain stringFor:kAccountID error:nil];
            
            if (UUIDString == nil) {
                UUIDString = [[NSUserDefaults standardUserDefaults] stringForKey:kAccountID];
            }
            
        }
        
        _UUIDString = UUIDString;
//#endif
    }
    
    return _UUIDString;
    
}

- (NSUUID *)UUID {
    
//#ifdef DEBUG
//
//    if (_UUID == nil) {
//
//        // Nikhil
//        _UUID = [[NSUUID alloc] initWithUUIDString:self.UUIDString];
////        _userID = @(1);
//
//        // Anuj
////        _UUID = [[NSUUID alloc] initWithUUIDString:@"4CE0BC0B-82E6-4B08-84F5-DE5C56774064"];
//        _userID = @(9);
//
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [NSNotificationCenter.defaultCenter postNotificationName:UserDidUpdate object:nil];
//        });
//    }
//
//    return _UUID;
//
//#endif
    
    if (_UUID == nil) {
        // check if the store already has one
        
        NSString *UUIDString = self.UUIDString;
        NSString *userID = [Keychain stringFor:kUserID error:nil];
        
        if (_userID && _userID.integerValue == 0) {
            _userID = nil;
            _UUID = nil;
            UUIDString = nil;
        }
        else {
            _userID = @([userID integerValue]);
        }

        // migrate from NSUserDefaults
        if (!UUIDString || !self.userID) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            UUIDString = [defaults stringForKey:kAccountID];

            if (UUIDString) {
                self.UUIDString = UUIDString;
                self.UUID = [[NSUUID alloc] initWithUUIDString:UUIDString];
            }

            NSInteger userID = [[defaults valueForKey:kUserID] integerValue];
            if (userID) {
                self.userID = @(userID);
            }
        }
        
        if (UUIDString == nil) {
            UUIDString = [NSUUID UUID].UUIDString;
        }
        
        if (UUIDString) {
            // we have one.
            _UUID = [[NSUUID alloc] initWithUUIDString:UUIDString];
            
            if (_userID == nil || _userID.integerValue == 0) {
                // build 21 (alpha) broke this. This is a patch for that.
                if (self.delegate) {

                    [self.delegate getUserInformation:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                        NSDictionary *user = [responseObject valueForKey:@"user"];
                        self.userID = @([[user valueForKey:@"id"] integerValue]);
                        
                        [NSNotificationCenter.defaultCenter postNotificationName:UserDidUpdate object:nil];
                        
                    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                        
                        if ([error.localizedDescription containsString:@"pass a valid user ID"] == YES) {
                            // user is most likely setting up the account.
                            return;
                        }
                        
                        [AlertManager showGenericAlertWithTitle:@"Error Loading User" message:error.localizedDescription];
                        
                    }];
                    
                }
                
            }
            else {
                [NSNotificationCenter.defaultCenter postNotificationName:UserDidUpdate object:nil];
            }
            
        }
        else {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSNotificationCenter.defaultCenter postNotificationName:YTUserNotFound object:nil];
            });
            
        }
        
    }
    
    return _UUID;
}

- (void)setUUIDString:(NSString *)UUIDString {
    
    _UUIDString = UUIDString;
    
    if (_UUIDString != nil) {
        [Keychain add:kUUIDString string:UUIDString];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (defaults) {
            [defaults setValue:UUIDString forKey:kUUIDString];
            [defaults synchronize];
        }
    }
    
}

- (NSNumber *)userID {
    
//#ifdef DEBUG
//
//    return @9;
//
//#endif
    
    if (_userID == nil) {
        NSString *userIDString = [Keychain stringFor:kUserID error:nil];
        
        if (userIDString == nil) {
            userIDString = [NSUserDefaults.standardUserDefaults valueForKey:kUserID];
            
            if (userIDString) {
                
                if ([userIDString isKindOfClass:NSString.class] == NO
                    && [userIDString respondsToSelector:@selector(stringValue)]) {
                    
                    userIDString = [(NSNumber *)userIDString stringValue];
                    
                }
                
                if (userIDString) {
                    [Keychain add:kUserID string:userIDString];
                }
            }
            
        }
        
        if (userIDString) {
            NSNumber *userID = @(userIDString.integerValue);
            
            _userID = userID;
        }
        
    }
    
    return _userID;
    
}

- (void)setUserID:(NSNumber *)userID {
    
    _userID = userID;
    
    if (_userID != nil) {
        
        [Keychain add:kUserID string:userID.stringValue];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if (defaults) {
            [defaults setValue:userID forKey:kUserID];
            [defaults synchronize];
        }
        
    }
}

@end
