//
//  ArticleVC+Toolbar.m
//  Yeti
//
//  Created by Nikhil Nigade on 02/12/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "ArticleVC+Toolbar.h"

@implementation ArticleVC (Toolbar)

- (void)setupToolbar:(UITraitCollection *)newCollection
{
    
    UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(didTapShare)];
    UIBarButtonItem *const flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    if (newCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        self.navigationItem.rightBarButtonItems = nil;
        self.toolbarItems = @[flex, share];
        self.navigationController.toolbarHidden = NO;
    }
    else {
        self.toolbarItems = nil;
        self.navigationController.toolbarHidden = YES;
        self.navigationItem.rightBarButtonItems = @[share];
    }
}

#pragma mark -

- (void)didTapShare {
    
    if (!self.item)
        return;
    
    NSString *title = self.item.articleTitle;
    NSURL *URL = formattedURL(@"%@", self.item.articleURL);
    
    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[title, URL] applicationActivities:nil];
    
    [self presentViewController:avc animated:YES completion:nil];
    
}

@end
