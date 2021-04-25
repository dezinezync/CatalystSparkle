//
//  AppKitGlue.m
//  elytramac
//
//  Created by Nikhil Nigade on 09/06/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AppKitGlue.h"
#import "elytramac-Swift.h"

typedef void (^successBlock)(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task);
typedef void (^errorBlock)(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task);

@interface FeedsManager : NSObject

- (void)deactivateAccountWithSuccess:(successBlock _Nonnull)successCB error:(errorBlock _Nonnull)errorCB;

@end

static AppKitGlue * SharedAppKitGlue = nil;

@interface AppKitGlue ()

@property (strong) PreferencesController *preferencesController;

@end

@implementation AppKitGlue

+ (instancetype)shared {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SharedAppKitGlue = [[AppKitGlue alloc] init];
    });
    
    return SharedAppKitGlue;
    
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        NSArray <NSString *> *fontNames = [NSFontManager sharedFontManager].availableFonts;
        
        __block BOOL hasNYBold = NO;
        __block BOOL hasNYBoldItalic = NO;
        
        [fontNames enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            if (hasNYBold == NO && [obj isEqualToString:@"NewYorkLarge-Bold"]) {
                hasNYBold = YES;
            }
            else if (hasNYBoldItalic == NO && [obj isEqualToString:@"NewYorkLarge-BoldItalic"]) {
                hasNYBoldItalic = YES;
            }
            
        }];
        
        if (hasNYBold && hasNYBoldItalic) {
            
            // has NY Bold Font installed.
            [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"hasNYBoldInstalled"];
            
        }
        else {
            
            [NSUserDefaults.standardUserDefaults setBool:NO forKey:@"hasNYBoldInstalled"];
            
        }
        
        [NSWorkspace.sharedWorkspace.notificationCenter addObserver:self selector:@selector(didWakeNotification:) name:NSWorkspaceDidWakeNotification object:nil];
        
    }
    
    return self;
    
}

- (void)openURL:(NSURL *)url inBackground:(BOOL)background {
    
    if (background) {
      
        NSWorkspaceOpenConfiguration *config = [NSWorkspaceOpenConfiguration configuration];
        config.activates = NO;
        
        [[NSWorkspace sharedWorkspace] openURL:url configuration:config completionHandler:nil];
    }
    else {
      [[NSWorkspace sharedWorkspace] openURL:url];
    }
    
}

/// https://developer.apple.com/forums/thread/127382
- (void)disableFullscreenButton:(NSWindow *)window {
    
    [window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenAuxiliary|NSWindowCollectionBehaviorFullScreenNone|NSWindowCollectionBehaviorFullScreenDisallowsTiling];
           
    NSButton *button = [window standardWindowButton:NSWindowZoomButton];
    [button setEnabled: NO];
    
}

- (void)didWakeNotification:(NSNotification *)note {
    
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(didWake:)]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate didWake:note];
        });
        
    }
    
}

/// https://github.com/thekarladam/fluidium/blob/4e4b7c7cf742a368d8f6a651ee149f1aec20d0a5/Fluidium/lib/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSImage-OAExtensions.m#L150
- (CGImageRef)imageForFileType:(NSString *)fileType {
    
    static NSMutableDictionary *imageDictionary = nil;
    id image;

    NSAssert(NSThread.isMainThread, @"+imageForFileType: is not thread-safe; must be called from the main thread");
    // We could fix this by adding locks around imageDictionary

    if (!fileType)
        return nil;
            
    if (imageDictionary == nil)
        imageDictionary = [[NSMutableDictionary alloc] init];

    image = [imageDictionary objectForKey:fileType];
    if (image == nil) {
#ifdef DEBUG
        // Make sure that our caching doesn't go insane (and that we don't ask it to cache insane stuff)
        NSLog(@"Caching workspace image for file type '%@'", fileType);
#endif
        image = [[NSWorkspace sharedWorkspace] iconForFileType:fileType];
        
        if (image == nil) {
            image = [NSNull null];
        }
        
        [imageDictionary setObject:image forKey:fileType];
    }
    
    if (image == [NSNull null]) {
        return nil;
    }
    
    // https://stackoverflow.com/a/2548861/1387258
    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)[image TIFFRepresentation], NULL);
    CGImageRef ref =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
    
    return ref;
    
}

- (void)showPreferencesController {
    
    if (self.preferencesController == nil) {
        self.preferencesController = [PreferencesController new];
    }
    
    [self.preferencesController show];
    
}

- (void)deactivateAccount:(void (^)(BOOL success, NSError *error))completionBlock {
    
    [(FeedsManager *)self.feedsManager deactivateAccountWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (completionBlock) {
            completionBlock(YES, nil);
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (completionBlock) {
            completionBlock(NO, error);
        }
        
    }];
    
}

@end
