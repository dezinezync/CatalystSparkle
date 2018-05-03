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
#import "YetiConstants.h"

#import "CheckWifi.h"

#import <DZKit/NSString+Date.h>

#import <DZNetworking/UIImageView+ImageLoading.h>

#import "YetiThemeKit.h"

@implementation TweetPara

- (BOOL)avoidsLazyLoading {
    return YES;
}

- (UIFont *)bodyFont
{
    if (!_bodyFont) {
        if (!NSThread.isMainThread) {
            __block UIFont *retval = nil;
            weakify(self);
            dispatch_sync(dispatch_get_main_queue(), ^{
                strongify(self);
                retval = [self bodyFont];
            });
            
            _bodyFont = retval;
            
            return _bodyFont;
        }
        
        __block UIFont * bodyFont = [UIFont systemFontOfSize:16.f];
        __block UIFont * baseFont;
        
        baseFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleBody] scaledFontForFont:bodyFont];
        
        bodyFont = nil;
        
        _bodyFont = baseFont;
    }
    
    return _bodyFont;
}

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

@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (weak, nonatomic) Content *content;

@end

@implementation Tweet

- (BOOL)showImage {
    if ([[NSUserDefaults.standardUserDefaults valueForKey:kDefaultsImageBandwidth] isEqualToString:ImageLoadingNever])
        return NO;
    
    else if([[NSUserDefaults.standardUserDefaults valueForKey:kDefaultsImageBandwidth] isEqualToString:ImageLoadingOnlyWireless]) {
        return CheckWiFi();
    }
    
    return YES;
}

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
        
        self.avatar.image = nil;
    }
    
    return self;
}

- (void)configureContent:(Content *)content {
    
    if (!content)
        return;
    
    _content = content;
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.backgroundColor = theme.isDark ? [UIColor colorWithRed:51/255.f green:53/255.f blue:55/255.f alpha:1.f] : [UIColor colorWithRed:235/255.f green:247/255.f blue:255/255.f alpha:1.f];
    self.textview.backgroundColor = self.backgroundColor;
    
    self.collectionView.backgroundColor = self.backgroundColor;
    
    [self.textview setText:content.content ranges:content.ranges attributes:content.attributes];
    self.textview.contentSize = [[self.textview attributedText] boundingRectWithSize:self.textview.bounds.size options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    
    self.usernameLabel.text = formattedString(@"@%@", [content.attributes valueForKey:@"username"]);
    self.usernameLabel.textColor = theme.isDark ? [UIColor colorWithRed:184/255.f green:208/255.f blue:230/255.f alpha:1.f] : [UIColor colorWithRed:77/255.f green:104/255.f blue:128/255.f alpha:1.f];
    
    weakify(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        strongify(self);
        
        NSString *avatarURI = [content.attributes valueForKey:@"avatar"];
        
        [self.avatar il_setImageWithURL:formattedURL(@"%@", avatarURI)];
    });
    
    self.timeLabel.text = [[(NSString *)[content.attributes valueForKey:@"created"] dateFromTimestamp] timeAgoSinceNow];
    
    if (!content.images || !content.images.count || ![self showImage]) {
        self.collectionView.hidden = YES;
        self.collectionViewHeight.constant = 0.f;
        self.collectionPadding.constant = 0.f;
    }
    else {
        
        [self setupCollectionView];
        
    }
}

- (void)setupCollectionView {
    
    if (!self.content)
        return;
    
    self.content.images = [self.content.images arrayByAddingObject:self.content.images.firstObject];
    
    if (self.content.images.count > 2) {
        // double height
        self.collectionViewHeight.constant = 128.f * 2;
    }
    
    if (self.content.images.count >= 2) {
        self.layout.itemSize = CGSizeMake((self.bounds.size.width - 16.f)/2.f, 128.f);
    }
    
    if (self.content.images.count == 1) {
        self.layout.itemSize = CGSizeMake(self.bounds.size.width - 16.f, 128.f);
    }
    
    [self.collectionView reloadData];
    
}

#pragma mark - Overrides

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    [self setupCollectionView];
}

- (CGSize)intrinsicContentSize
{
    CGSize size = CGSizeMake(self.bounds.size.width, 0.f);
    
    if (!self.collectionView.isHidden) {
        size.height += self.collectionView.bounds.size.height;
    }
    
    size.height += [self.textview sizeThatFits:CGSizeMake(size.width - (LayoutPadding * 2), CGFLOAT_MAX)].height + ((self.textview.bodyFont.pointSize * MAX(1.333f, self.textview.paragraphStyle.lineHeightMultiple)) * 4);
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
    cell.backgroundColor = self.backgroundColor;
    cell.imageView.backgroundColor = self.backgroundColor;
    
    Content *image = [self.content.images objectAtIndex:indexPath.item];
    
    weakify(cell);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        strongify(cell);
        [cell.imageView il_setImageWithURL:formattedURL(@"%@", image.url)];
    });
    
    return cell;
    
}

#pragma mark - Interactions

- (IBAction)didTapUsername:(UITapGestureRecognizer *)sender {

    NSString *username = [self.content.attributes valueForKey:@"username"];
    
    NSURL *URL = formattedURL(@"yeti://twitter/user/%@", username);
    
    [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:nil];
    
}

- (IBAction)didTapTimestamp:(UITapGestureRecognizer *)sender {
    
    NSString *identifer = [self.content.attributes valueForKey:@"id"];
    
    NSURL *URL = formattedURL(@"yeti://twitter/status/%@", identifer);
    
    [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:nil];
    
}

@end
