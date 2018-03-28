//
//  Tweet.m
//  Yeti
//
//  Created by Nikhil Nigade on 28/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "Tweet.h"
#import "Paragraph.h"
#import "NSDate+DateTools.h"
#import "LayoutConstants.h"
#import "TweetImage.h"

#import <DZKit/NSString+Date.h>

#import <DZNetworking/UIImageView+ImageLoading.h>

@implementation TweetPara

- (NSParagraphStyle *)paragraphStyle {
    
    if (!_paragraphStyle) {
        NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
        style.lineHeightMultiple = 1.44444f;
        
        style.firstLineHeadIndent = LayoutPadding;
        style.headIndent = LayoutPadding;
        
        _paragraphStyle = style.copy;
    }
    
    return _paragraphStyle;
    
}

@end

@interface Tweet () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *layout;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionPadding;

@property (weak, nonatomic) IBOutlet Paragraph *textview;
@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (weak, nonatomic) Content *content;

@end

@implementation Tweet

- (instancetype)initWithNib
{
    if (self = [super initWithNib]) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass(TweetImage.class) bundle:nil] forCellWithReuseIdentifier:kTweetCell];
        self.collectionView.contentInset = UIEdgeInsetsZero;
        self.collectionView.layoutMargins = UIEdgeInsetsZero;
        self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
    }
    
    return self;
}

- (void)configureContent:(Content *)content {
    
    if (!content)
        return;
    
    _content = content;
    
    [self.textview setText:content.content ranges:content.ranges attributes:content.attributes];
    
    self.usernameLabel.text = formattedString(@"@%@", [content.attributes valueForKey:@"username"]);
    
    [self.avatar il_setImageWithURL:[content.attributes valueForKey:@"avatar"]];
    
    self.timeLabel.text = [[(NSString *)[content.attributes valueForKey:@"created"] dateFromTimestamp] timeAgoSinceNow];
    
    if (!content.images || !content.images.count) {
        self.collectionView.hidden = YES;
        self.collectionViewHeight.constant = 0.f;
        self.collectionPadding.constant = 0.f;
    }
    else {
        
        if (content.images.count > 2) {
            // double height
            self.collectionViewHeight.constant = 128.f * 2;
        }
        
        if (content.images.count >= 2) {
            self.layout.itemSize = CGSizeMake((self.bounds.size.width - (LayoutPadding * 2))/2.f, 128.f);
        }
        
        if (content.images.count == 1) {
            self.layout.itemSize = CGSizeMake(self.bounds.size.width - (LayoutPadding * 2), 128.f);
        }
        else if (fmod(content.images.count, 2.f) == 0) {
            // even numbers
        }
        else {
            // odd numbers
        }
        
        [self.collectionView reloadData];
        
    }
}

#pragma mark - Overrides

- (CGSize)intrinsicContentSize
{
    CGSize size = CGSizeMake(self.bounds.size.width, 0.f);
    
    if (!self.collectionView.isHidden) {
        size.height += self.collectionView.bounds.size.height;
    }
    
    size.height += [self.textview sizeThatFits:CGSizeMake(size.width - (LayoutPadding * 2), CGFLOAT_MAX)].height;
    size.height += [self.avatar.superview sizeThatFits:CGSizeMake(size.width - (LayoutPadding * 2), CGFLOAT_MAX)].height;
    // add the inter-elements padding
    size.height += LayoutPadding * (self.collectionView.isHidden ? 2 : 3);
    
    return size;
}

#pragma mark - <UICollectionViewDatasource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.content ? 1 : 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (!self.content)
        return 0;
    
    return self.content.images.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TweetImage *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kTweetCell forIndexPath:indexPath];
    
    Content *image = [self.content.images objectAtIndex:indexPath.item];
    
    [cell.imageView il_setImageWithURL:image.url success:^(UIImage * _Nonnull image, NSURL * _Nonnull URL) {
        
    } error:^(NSError * _Nonnull error) {
        
    }];
    
    return cell;
    
}

@end
