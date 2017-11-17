//
//  ArticleVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "ArticleVC.h"
#import "Content.h"

#import "Paragraph.h"
#import "Heading.h"
#import "Blockquote.h"
#import "List.h"
#import "Aside.h"
#import "Youtube.h"

#import "UIImageView+ImageLoading.h"
#import "NSAttributedString+Trimming.h"

@interface ArticleVC ()

@property (nonatomic, weak) FeedItem *item;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIStackView *stackView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollBottom;
@property (weak, nonatomic) UIView *last; // reference to the last setup view.

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
    
    [self addTitle];
    
    // add Body
    for (Content *content in self.item.content) { @autoreleasepool {
        [self processContent:content];
    } }
    
    _last = nil;
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

#pragma mark -

- (void)addTitle {
    
    NSString *subline = formattedString(@"%@ | %@", self.item.author?:@"unknown", self.item.timestamp);
    NSString *formatted = formattedString(@"%@\n%@\n", self.item.articleTitle, subline);
    
    NSMutableParagraphStyle *para = [[NSMutableParagraphStyle alloc] init];
    para.lineHeightMultiple = 1.2f;
    
    NSDictionary *baseAttributes = @{NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1],
                                     NSForegroundColorAttributeName: UIColor.blackColor,
                                     NSParagraphStyleAttributeName: para
                                     };
    
    NSDictionary *subtextAttributes = @{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline],
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
            for (NSDictionary *dict in (NSArray *)[content content]) { @autoreleasepool {
                
                Content *subcontent = [Content instanceFromDictionary:dict];
                [self processContent:subcontent];
                
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
}

- (void)addLinebreak {
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 24.f);
    
    UIView *linebreak = [[UIView alloc] initWithFrame:frame];
    
    _last = linebreak;
    
    [self.stackView addArrangedSubview:linebreak];
}

- (void)addImage:(Content *)content {
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 32.f);
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.f];
    
    _last = imageView;
    
    [self.stackView addArrangedSubview:imageView];
    [imageView.heightAnchor constraintEqualToConstant:32.f].active = YES;
    [imageView il_setImageWithURL:content.url];
    
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
