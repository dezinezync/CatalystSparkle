//
//  ArticleVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "ArticleVC+Toolbar.h"
#import "FeedsManager+KVS.h"
#import "Content.h"

#import "Paragraph.h"
#import "Heading.h"
#import "Blockquote.h"
#import "List.h"
#import "Aside.h"
#import "Youtube.h"
#import "Image.h"

#import <DZNetworking/UIImageView+ImageLoading.h>
#import "NSAttributedString+Trimming.h"
#import <DZKit/NSArray+Safe.h>
#import <DZKit/NSArray+RZArrayCandy.h>

@interface ArticleVC ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIStackView *stackView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollBottom;
@property (weak, nonatomic) UIView *last; // reference to the last setup view.
@property (weak, nonatomic) id nextItem; // next item which will be processed
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loader;

@end

@implementation ArticleVC

- (instancetype)initWithItem:(FeedItem *)item
{
    if (self = [super initWithNibName:NSStringFromClass(ArticleVC.class) bundle:nil]) {
        self.item = item;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [[self.stackView arrangedSubviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        [self.stackView removeArrangedSubview:obj];
        [obj removeFromSuperview];
        
    }];
    
    [self setupToolbar:self.traitCollection];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    
    [self.loader startAnimating];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
#ifdef DEBUG
    NSDate *start = NSDate.date;
#endif
    
    // add Body
    [self addTitle];
    
    NSUInteger idx = 0;
    
    self.stackView.hidden = YES;
    
    for (Content *content in self.item.content) { @autoreleasepool {
        //            _nextItem = [self.item.content safeObjectAtIndex:idx+1];
        [self processContent:content];
        
        idx++;
    } }
    
    self.item.primedContent = self.stackView.arrangedSubviews;
    
    [self.loader stopAnimating];
    [self.loader removeFromSuperview];
    
    self.stackView.hidden = NO;
    
    _last = nil;
    
#ifdef DEBUG
    DDLogInfo(@"Processing: %@", @([NSDate.date timeIntervalSinceDate:start]));
#endif
    
    if (self.item && !self.item.isRead)
        [MyFeedsManager article:self.item markAsRead:YES];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewSafeAreaInsetsDidChange
{
    if (UIScreen.mainScreen.scale == 3.f && self.view.bounds.size.height > 667.f) {
        self.scrollBottom.constant = -self.view.safeAreaInsets.bottom;
    }
    else {
        self.scrollBottom.constant = 0;
    }
    
    [super viewSafeAreaInsetsDidChange];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    weakify(self);
    
    if (coordinator) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            
            strongify(self);
            
            [self setupToolbar:newCollection];
            
        } completion:nil];
    }
    else
        [self setupToolbar:newCollection];
    
}

#pragma mark -

- (void)addTitle {
    
    NSString *subline = formattedString(@"%@ | %@", self.item.author?:@"unknown", self.item.timestamp);
    NSString *formatted = formattedString(@"%@\n%@\n", self.item.articleTitle, subline);
    
    NSMutableParagraphStyle *para = [[NSMutableParagraphStyle alloc] init];
    para.lineHeightMultiple = 1.2f;
    
    UIFont * titleFont = [UIFont systemFontOfSize:36.f weight:UIFontWeightSemibold];
    UIFont * baseFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:titleFont];
    
    NSDictionary *baseAttributes = @{NSFontAttributeName : baseFont,
                                     NSForegroundColorAttributeName: UIColor.blackColor,
                                     NSParagraphStyleAttributeName: para
                                     };
    
    NSDictionary *subtextAttributes = @{NSFontAttributeName: [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleSubheadline] scaledFontForFont:[UIFont systemFontOfSize:20.f weight:UIFontWeightMedium]],
                                        NSForegroundColorAttributeName: [UIColor colorWithWhite:0.f alpha:0.54f],
                                        NSParagraphStyleAttributeName: para
                                        };
    
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:formatted attributes:baseAttributes];
    [attrs setAttributes:subtextAttributes range:[formatted rangeOfString:subline]];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.stackView.bounds.size.width, 0.f)];
    label.numberOfLines = 0;
    label.attributedText = attrs;
    [label sizeToFit];
    
    [self.stackView addArrangedSubview:label];
    
}

- (void)processContent:(Content *)content {
    if ([content.type isEqualToString:@"container"]) {
        if ([(NSArray *)content.content count]) {
            
            NSUInteger idx = 0;
            
            for (NSDictionary *dict in (NSArray *)[content content]) { @autoreleasepool {
                
                Content *subcontent = [Content instanceFromDictionary:dict];
                
//                _nextItem = [(NSArray *)(content.content) safeObjectAtIndex:idx+1];
                
                [self processContent:subcontent];
                
                idx++;
            }}
        }
    }
    else if ([content.type isEqualToString:@"paragraph"] && content.content.length) {
        [self addParagraph:content];
    }
    else if ([content.type isEqualToString:@"heading"] && content.content.length) {
        [self addHeading:content];
    }
    else if ([content.type isEqualToString:@"linebreak"] && _last && ![_last isKindOfClass:Paragraph.class]) {
        [self addLinebreak];
    }
    else if ([content.type isEqualToString:@"image"]) {
        [self addImage:content];
    }
    else if ([content.type isEqualToString:@"blockquote"]) {
        [self addQuote:content];
    }
    else if ([content.type containsString:@"list"]) {
        [self addList:content];
    }
    else if ([content.type isEqualToString:@"aside"]) {
        
        if (content.content.length > 140)
            [self addParagraph:content];
        else
            [self addAside:content];
        
    }
    else if ([content.type isEqualToString:@"youtube"]) {
        [self addYoutube:content];
    }
}

- (void)addParagraph:(Content *)content {
    
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 0);
    
    Paragraph *para = [[Paragraph alloc] initWithFrame:frame];
    
    if ([_last isKindOfClass:Heading.class])
        para.afterHeading = YES;
    
    NSNumber *hasPara = [self.stackView.arrangedSubviews rz_reduce:^id(__kindof NSNumber *prev, __kindof UIView *current, NSUInteger idx, NSArray *array) {
        BOOL retval = prev.boolValue || [current isKindOfClass:Paragraph.class];
        return @(retval);
    } initialValue:@NO];
    
    if ([_last isKindOfClass:Image.class]
        && [self.stackView.arrangedSubviews.lastObject isKindOfClass:UIView.class] && hasPara.boolValue
        && content.content.length <= 100)
        para.caption = YES;
    
    if ([_last isKindOfClass:Paragraph.class] && ![(Paragraph *)_last isCaption] && !para.isCaption) {
        
        // since the last one is a paragraph as well, simlpy append to it.
        Paragraph *last = (Paragraph *)_last;
        
        NSMutableAttributedString *attrs = last.attributedText.mutableCopy;
        
        NSAttributedString *newAttrs = [para processText:content.content ranges:content.ranges];
        
        [attrs appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        [attrs appendAttributedString:newAttrs];
        
        last.attributedText = attrs.copy;
        attrs = nil;
        newAttrs = nil;
        return;
    }
    
    [para setText:content.content ranges:content.ranges];
    
    frame.size.height = para.intrinsicContentSize.height;
    para.frame = frame;
    
    _last = para;
    
    [self.stackView addArrangedSubview:para];
}

- (void)addHeading:(Content *)content {
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 0);
    
    Heading *heading = [[Heading alloc] initWithFrame:frame];
    heading.level = content.level.integerValue;
    heading.text = content.content;
    
    frame.size.height = heading.intrinsicContentSize.height;
    heading.frame = frame;
    
    _last = heading;
    
    [self.stackView addArrangedSubview:heading];
    
    [self addLinebreak];
}

- (void)addLinebreak {
    // this rejects multiple \n in succession which may be undesired.
    if ([_last isKindOfClass:UIView.class])
        return;
    
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 24.f);
    
    UIView *linebreak = [[UIView alloc] initWithFrame:frame];
    [linebreak.heightAnchor constraintEqualToConstant:24.f].active = YES;
    _last = linebreak;
    
    [self.stackView addArrangedSubview:linebreak];
}

- (void)addImage:(Content *)content {
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 32.f);
    
    Image *imageView = [[Image alloc] initWithFrame:frame];
    
    _last = imageView;
    
    [self.stackView addArrangedSubview:imageView];
    [imageView.heightAnchor constraintEqualToConstant:32.f].active = YES;
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [imageView il_setImageWithURL:content.url];
//    });
    
    [self addLinebreak];
}

- (void)addQuote:(Content *)content {
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 32.f);
    
    Blockquote *para = [[Blockquote alloc] initWithFrame:frame];
    
    [para setText:content.content ranges:content.ranges];
    
    frame.size.height = para.intrinsicContentSize.height;
    para.frame = frame;
    
    _last = para;
    
    [self.stackView addArrangedSubview:para];
}

- (void)addList:(Content *)content {
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 32.f);
    
    List *list = [[List alloc] initWithFrame:frame];
    
    [list setContent:content];
    
    frame.size.height = list.intrinsicContentSize.height;
    list.frame = frame;
    
    _last = list;
    
    [self.stackView addArrangedSubview:list];
}

- (void)addAside:(Content *)content
{
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 0);
    
    Aside *para = [[Aside alloc] initWithFrame:frame];
    
    if ([_last isKindOfClass:Heading.class])
        para.afterHeading = YES;
    
    [para setText:content.content ranges:content.ranges];
    
    frame.size.height = para.intrinsicContentSize.height;
    para.frame = frame;
    
    _last = para;
    
    [self.stackView addArrangedSubview:para];
}

- (void)addYoutube:(Content *)content {
    
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 0);
    Youtube *youtube = [[Youtube alloc] initWithFrame:frame];
    youtube.URL = [NSURL URLWithString:content.url];
    
    _last = youtube;
    
    [self.stackView addArrangedSubview:youtube];
}

@end
