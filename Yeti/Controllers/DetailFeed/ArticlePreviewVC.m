//
//  ArticlePreviewVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/06/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "ArticlePreviewVC.h"
#import "NSString+ImageProxy.h"
#import <DZNetworking/UIImageView+ImageLoading.h>
#import "YetiConstants.h"

#import <DZKit/NSString+Extras.h>
#import <DZKit/NSArray+RZArrayCandy.h>

#import "Content.h"

@interface ArticlePreviewVC ()

@property (nonatomic, weak) FeedItem *item;

@end

@implementation ArticlePreviewVC

+ (instancetype)instanceForFeed:(FeedItem *)item {
    
    ArticlePreviewVC *instance = [[ArticlePreviewVC alloc] initWithNibName:NSStringFromClass(ArticlePreviewVC.class) bundle:[NSBundle bundleForClass:ArticlePreviewVC.class]];
    
    instance.item = item;
    
    return instance;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
//    self.view.translatesAutoresizingMaskIntoConstraints = NO;
//    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
//    self.captionLabel.translatesAutoresizingMaskIntoConstraints = NO;
//    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    if (self.item != nil) {
        [self configureForFeed:self.item];
    }
    
}

- (void)configureForFeed:(FeedItem *)item {
    
    if (item == nil) {
        return;
    }
    
    if (item.coverImage != nil) {
        self.imageView.hidden = NO;
        
        CGFloat maxWidth = self.view.bounds.size.width * UIScreen.mainScreen.scale;
        
        NSString *url = [item.coverImage pathForImageProxy:NO maxWidth:maxWidth quality:0.f];
        
        [self.imageView il_setImageWithURL:url success:^(UIImage * _Nonnull image, NSURL * _Nonnull URL) {
          
            self.imageView.image = image;
            
            self.imageView.layer.cornerCurve = kCACornerCurveContinuous;
            
            self.imageView.layer.cornerRadius = 8.f;
            self.imageView.layer.masksToBounds = YES;
            
        } error:nil];
    }
    else {
        self.imageView.hidden = YES;
    }
    
    self.titleLabel.text = item.articleTitle ? item.articleTitle : @"Untitled";
    
    if ([([item articleTitle] ?: @"") isBlank] && item.content && item.content.count) {
        // find the first paragraph
        Content *content = [item.content rz_reduce:^id(Content *prev, Content *current, NSUInteger idx, NSArray *array) {
            
            if (prev && [prev.type isEqualToString:@"paragraph"]) {
                return prev;
            }
            
            return current;
        }];
        
        if (content) {
            self.titleLabel.text = content.content;
        }
    }
    
    [self.titleLabel sizeToFit];
    
    self.captionLabel.text = item.summary;
    self.captionLabel.numberOfLines = SharedPrefs.previewLines ?: 3;
    
    [self.captionLabel sizeToFit];
    
//    [self.view setNeedsLayout];
//    [self.view layoutIfNeeded];
    
}

//- (CGSize)preferredContentSize {
//    
//    CGFloat width = 0.f, height = LayoutPadding * 2.f;
//    
//    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad
//        || self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
//        
//        width = self.view.bounds.size.width;
//        
//    }
//    else {
//        width = [UIApplication sharedApplication].keyWindow.bounds.size.width;
//    }
//    
//    width = width - (LayoutPadding * 2);
//    
//    CGSize fittingSize = [self.imageView systemLayoutSizeFittingSize:CGSizeMake(width, CGFLOAT_MAX) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityDefaultLow];
//    
//    height += fittingSize.height;
//    
//    if (fittingSize.height > 0) {
//        height += LayoutPadding;
//    }
//    
//    fittingSize = [self.titleLabel sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
//    
//    height += fittingSize.height + LayoutPadding;
//    
//    fittingSize = [self.captionLabel sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
//    
//    height += fittingSize.height;
//    
//    return CGSizeMake(0.f, height);
//    
//}

@end
