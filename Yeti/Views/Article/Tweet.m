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

#import "CheckWifi.h"

#import "Elytra-Swift.h"

#import <DZKit/NSString+Date.h>

#import <LinkPresentation/LinkPresentation.h>

@interface UIGestureRecognizerTarget : NSObject

@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;

@end

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

@interface Tweet () <UICollectionViewDelegate, UICollectionViewDataSource> {
    BOOL _usingLinkPresentation;
}

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *layout;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionPadding;

@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (weak, nonatomic) Content *content;

@property (weak, nonatomic) LPLinkView *linkView API_AVAILABLE(ios(13.0));
@property (nonatomic, copy) NSURL *linkURL;

@end

@implementation Tweet

- (BOOL)showImage {
        
    if (_usingLinkPresentation) {
        return NO;
    }
    
    if ([SharedPrefs.imageLoading isEqualToString:ImageLoadingNever])
        return NO;
    
    else if([SharedPrefs.imageBandwidth isEqualToString:ImageLoadingOnlyWireless]) {
        return CheckWiFi();
    }
    
    return YES;
}

- (instancetype)initWithNib {
    if (self = [super initWithNib]) {
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.collectionView.hidden = YES;
        self.textview.hidden = YES;
        self.avatar.hidden = YES;
        self.usernameLabel.hidden = YES;
        self.timeLabel.hidden = YES;
        
        _usingLinkPresentation = YES;
        
        self.backgroundColor = [UIColor clearColor];
        
    }
    
    return self;
}

- (void)configureContent:(Content *)content {
    
    if (!content)
        return;
    
    _content = content;
    
    [self addTweetForOS13:content];
}

- (void)addTweetForOS13:(Content *)content {
    
    if (content.attributes == nil) {
        return;
    }
    
    NSURL *url = formattedURL(@"https://twitter.com/%@/status/%@", content.attributes[@"username"], content.attributes[@"id"]);
    
    LPMetadataProvider *metadata = [[LPMetadataProvider alloc] init];
    
    [metadata startFetchingMetadataForURL:url completionHandler:^(LPLinkMetadata * _Nullable metadata, NSError * _Nullable error) {

        if (error) {
            NSLog(@"Error loading metadata: %@", error);
        }
        else {
            NSLog(@"Metadata: %@", metadata);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSString *url = metadata.URL.absoluteString;
                NSString *statusID = [url lastPathComponent];
                
                url = [NSString stringWithFormat:@"yeti://twitter/status/%@", statusID];
                self.linkURL = [NSURL URLWithString:url];
               
                LPLinkView *view = [[LPLinkView alloc] initWithMetadata:metadata];
                view.translatesAutoresizingMaskIntoConstraints = NO;
                view.frame = CGRectMake(0, 0, self.bounds.size.width, 0.f);
                view.showsLargeContentViewer = YES;
                
                [view sizeToFit];
                [view layoutSubviews];
             
                [self addSubview:view];
                
                self.linkView = view;
                
                // Disable built-in tap gestures
                NSArray <UITapGestureRecognizer *> *tapGestureRecognizers = [view valueForKey:@"tapGestureRecognizers"];
                
                for (UITapGestureRecognizer *tap in tapGestureRecognizers) {
                    
                    NSArray <UIGestureRecognizerTarget *> *targets = [tap valueForKey:@"targets"];
                    
                    for (UIGestureRecognizerTarget *target in targets) {
                        
                        [tap removeTarget:target.target action:target.action];
                        
                    }
                    
                    [tap addTarget:self action:@selector(didTapLinkPreview)];
                    
                }
                
                // add our own
//                UITapGestureRecognizer *ourTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapLinkPreview)];
//                [view addGestureRecognizer:ourTap];
                
                [NSLayoutConstraint activateConstraints:@[[view.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
                                                          [view.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
                                                          [self.widthAnchor constraintEqualToAnchor:view.widthAnchor],
                                                          [self.heightAnchor constraintEqualToAnchor:view.heightAnchor]]];
                
                [UIView animateWithDuration:0.25 animations:^{
                    
                    [self invalidateIntrinsicContentSize];
                    [self.superview setNeedsLayout];
                    
                    // this causes the scroll view to bounce.
//                    [self.superview layoutIfNeeded];
                    
                }];
                
            });
            
        }

    }];
    
}

- (void)setupCollectionView {
    
    if (!self.content)
        return;
    
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

- (void)didTapLinkPreview {
    
    [UIApplication.sharedApplication openURL:self.linkURL options:@{} completionHandler:nil];
    
}

#pragma mark - Overrides

- (CGSize)intrinsicContentSize {
    CGSize size = CGSizeMake(self.bounds.size.width, 0.f);
    
    if (_usingLinkPresentation == YES && self.linkView != nil) {
        CGSize linkViewSize = [self.linkView sizeThatFits:CGSizeMake(size.width, CGFLOAT_MAX)];
        
        NSLog(@"Tweet view size: %@", NSStringFromCGSize(linkViewSize));
        
        return linkViewSize;
    }
    
    return size;
    
}

#pragma mark - <UICollectionViewDatasource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.content ? 1 : 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (!self.content)
        return 0;
    
    return self.content.images.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TweetImage *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kTweetCell forIndexPath:indexPath];
    cell.backgroundColor = self.backgroundColor;
    cell.imageView.backgroundColor = self.backgroundColor;
    
//    Content *image = [self.content.images objectAtIndex:indexPath.item];
//
//    weakify(cell);
//
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        strongify(cell);
//        [cell.imageView il_setImageWithURL:formattedURL(@"%@", image.url)];
//    });
    
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
