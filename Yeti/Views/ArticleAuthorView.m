//
//  ArticleAuthorView.m
//  Yeti
//
//  Created by Nikhil Nigade on 28/03/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "ArticleAuthorView.h"
#import "TypeFactory.h"
#import "YetiThemeKit.h"
#import "YetiConstants.h"

@interface ArticleAuthorView () {
    BOOL _didAddHorizontalConstraints;
}

@property (weak, nonatomic) IBOutlet UIStackView *mainStackView;

@end

@implementation ArticleAuthorView

- (instancetype)initWithNib {
    
    if (self = [super initWithNib]) {
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.titleLabel.font = TypeFactory.shared.titleFont;
        
        UIFont *font = TypeFactory.shared.subtitleFont;
        
        for (UILabel *label in @[self.titleLabel, self.blogLabel, self.authorLabel]) {
            
            if (label != self.titleLabel) {
                label.font = font;
            }
            
            label.textColor = [[YTThemeKit theme] subtitleColor];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.adjustsFontForContentSizeCategory = YES;
        }
        
        UIImage *image = [[UIImage imageNamed:@"mercury"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.mercurialButton setImage:image forState:UIControlStateNormal];
        
        self.mercurialButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        // we do not observe this as the article interface is redrawn when the theme changes
//        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didUpdateTheme) name:kDidUpdateTheme object:nil];
        [self didUpdateTheme];
        
    }
    
    return self;
    
}

- (void)didMoveToSuperview {
    
    [super didMoveToSuperview];
    
    if (self.superview != nil && self->_didAddHorizontalConstraints == NO) {
        
        UILayoutGuide *readable = self.superview.readableContentGuide;
        [self.mainStackView.leadingAnchor constraintEqualToAnchor:readable.leadingAnchor constant:LayoutPadding/2].active = YES;
        [self.mainStackView.trailingAnchor constraintEqualToAnchor:readable.trailingAnchor constant:LayoutPadding/2].active = YES;
        
    }
    
}

#pragma mark - Setters

- (void)setMercurialed:(BOOL)mercurialed {
    
    _mercurialed = mercurialed;
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.mercurialButton.tintColor = mercurialed ? [theme tintColor] : [theme borderColor];
    
    [self.mercurialButton setNeedsDisplay];
    
}

#pragma mark -

- (void)didUpdateTheme {
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.titleLabel.textColor = theme.titleColor;
    self.blogLabel.textColor = theme.tintColor;
    self.authorLabel.textColor = theme.captionColor;
    
    for (UILabel *label in @[self.titleLabel, self.blogLabel, self.authorLabel]) {
        label.backgroundColor = theme.articleBackgroundColor;
        
        if (label.opaque == NO) {
            label.opaque = YES;
        }
        
        [label setNeedsDisplay];
    }
    
    self.backgroundColor = theme.articleBackgroundColor;
    self.mercurialButton.backgroundColor = theme.backgroundColor;
    self.mercurialButton.opaque = YES;
    
}

- (IBAction)mercurialButton:(id)sender {
    
    if (self.mercurialed == YES) {
        return;
    }
    
    // disable it so the action does not trigger twice.
    self.mercurialButton.enabled = NO;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTapMercurialButton:completion:)]) {
        
        weakify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            strongify(self);
            
            [self.delegate didTapMercurialButton:sender completion:^(BOOL completed) {
               
                dispatch_async(dispatch_get_main_queue(), ^{
                   
                    if (completed == YES) {
                        self.mercurialed = YES;
                    }
                    
                    // if the action was completed, then we disable
                    // the button, which is the opposite of completed.
                    self.mercurialButton.enabled = !completed;
                    
                });
                
            }];
            
        });
        
    }
    else {
        // nothing else to do
        // re-enable the button
        self.mercurialButton.enabled = YES;
    }
    
}

@end
