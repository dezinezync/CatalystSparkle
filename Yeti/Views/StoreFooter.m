//
//  StoreFooter.m
//  Store
//
//  Created by Nikhil Nigade on 13/07/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "StoreFooter.h"

@interface StoreFooter ()

@end

@implementation StoreFooter

- (instancetype)initWithNib {
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:self.class]];
    self = [[nib instantiateWithOwner:self options:nil] objectAtIndex:0];
    
    {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.footerLabel.text = nil;
        
#if TARGET_OS_MACCATALYST
        [self.buyButton setTitle:@"Buy Now" forState:UIControlStateNormal];
#endif
    }
    
    return self;
}

@end
