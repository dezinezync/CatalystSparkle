//
//  AuthorBioVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 15/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AuthorBioVC.h"
#import "YetiThemeKit.h"

@interface AuthorBioVC () 

@end

@implementation AuthorBioVC

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    self.view.backgroundColor = theme.backgroundColor;
    self.para.backgroundColor = theme.backgroundColor;
    
    [self.para setContentOffset:CGPointZero];
    
}

#pragma mark - Getters

- (UIModalPresentationStyle)modalPresentationStyle {
    return UIModalPresentationPopover;
}

- (CGSize)preferredContentSize {
    
    CGFloat width = UIScreen.mainScreen.bounds.size.width;
    CGFloat height = [[UIApplication sharedApplication].keyWindow.rootViewController view].bounds.size.height;
    
    width = MIN(375, width);
    
    height = MIN(375, MIN(height, self.para.contentSize.height + (self.para.bodyFont.pointSize * [Paragraph paragraphStyle].lineHeightMultiple * 0.75)));
    
    CGSize size = CGSizeMake(width, height + 32.f);
    
    return size;
    
}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

@end
