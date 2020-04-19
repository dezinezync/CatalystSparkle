//
//  CollectionHeader.m
//  Yeti
//
//  Created by Nikhil Nigade on 29/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "CollectionHeader.h"
#import <DZTextKit/YetiThemeKit.h>

NSString * const kCollectionHeader = @"com.yeti.collection.header";

@implementation CollectionHeader

#pragma mark - Setters
- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    
    self.label.backgroundColor = backgroundColor;
    self.imageView.backgroundColor = backgroundColor;
}

@end
