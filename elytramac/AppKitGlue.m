//
//  AppKitGlue.m
//  elytramac
//
//  Created by Nikhil Nigade on 09/06/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AppKitGlue.h"

static AppKitGlue * SharedAppKitGlue = nil;

@implementation AppKitGlue

+ (instancetype)shared {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SharedAppKitGlue = [[AppKitGlue alloc] init];
    });
    
    return SharedAppKitGlue;
    
}

- (CGColorRef)CTColorForName:(NSString *)name {
    
    SEL sel = NSSelectorFromString(name);
    
    if ([NSColor respondsToSelector:sel] == YES) {
        
        NSColor *color = [NSColor performSelector:sel];
        
        if (color != nil) {
            
            CGColorRef cgColor = color.CGColor;
            
            return cgColor;
            
//            CGFloat red, green, blue, alpha;
//
//            [color getRed:&red green:&green blue:&blue alpha:&alpha];
//
//            return @[@(red), @(green), @(blue), @(alpha)];
            
        }
        
        return nil;
        
    }
    
    return nil;
    
}

- (void)ct_showAlertWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitle:(NSString *)otherButtonTitle completionHandler:(void (^ _Nullable)(NSString * _Nonnull))completionHandler {
    
    NSAlert *alert = [[NSAlert alloc] init];
    
    [alert setMessageText:(title ?: @"")];
    
    if (message) {
        [alert setInformativeText:message];
    }
    
    if (cancelButtonTitle != nil) {
        
        NSButton *button = [alert addButtonWithTitle:@"Cancel"];
        button.tag = 0;
        
        if (otherButtonTitle != nil) {
        
            button = [alert addButtonWithTitle:@"Ok"];
            button.tag = 1;
            
        }
        
    }
    else {
        NSButton *button = [alert addButtonWithTitle:@"Ok"];
        button.tag = 0;
    }
    
    NSModalResponse responseTag = [alert runModal];
    
    if (completionHandler) {
        
        NSButton *button = [alert buttons][responseTag];
        
        completionHandler(button.title);
        
    }
    
}

- (void)openURL:(NSURL *)url inBackground:(BOOL)background {
    
    if (background) {
      
        NSArray* urls = [NSArray arrayWithObject:url];
      
        [[NSWorkspace sharedWorkspace] openURLs:urls withAppBundleIdentifier:nil options:NSWorkspaceLaunchWithoutActivation additionalEventParamDescriptor:nil launchIdentifiers:nil];
    }
    else {
      [[NSWorkspace sharedWorkspace] openURL:url];
    }
    
}

@end
