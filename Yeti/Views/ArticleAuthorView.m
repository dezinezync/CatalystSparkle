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

@property (weak, nonatomic) IBOutlet UIView *activityView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation ArticleAuthorView

- (instancetype)initWithNib {
    
    if (self = [super initWithNib]) {
        
        self.backgroundColor = UIColor.systemBackgroundColor;
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.titleLabel.font = TypeFactory.shared.titleFont;

        UIFont *font = TypeFactory.shared.caption1Font;
        
#if !TARGET_OS_MACCATALYST
        font = TypeFactory.shared.subtitleFont;
#endif

        for (UILabel *label in @[self.titleLabel, self.blogLabel, self.authorLabel]) {

            if (label != self.titleLabel) {
                label.font = font;
            }

            label.textColor = UIColor.secondaryLabelColor;
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.adjustsFontForContentSizeCategory = YES;
        }
        
        UIImageConfiguration *imageConfig = [UIImageSymbolConfiguration  configurationWithWeight:UIImageSymbolWeightSemibold];
        
        UIImage *image = [[UIImage systemImageNamed:@"m.square" withConfiguration:imageConfig] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        [self.mercurialButton setImage:image forState:UIControlStateNormal];
        
        self.mercurialButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        if (@available(iOS 13.4, *)) {
            self.mercurialButton.pointerInteractionEnabled = YES;
        }
        
        self.activityView.hidden = YES;
        self.activityIndicator.hidden = YES;
        
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
    
    UIImageConfiguration *imageConfig = [UIImageSymbolConfiguration  configurationWithWeight:UIImageSymbolWeightSemibold];
    
    UIImage *image = [[UIImage systemImageNamed:@"m.square.fill" withConfiguration:imageConfig] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    [self.mercurialButton setImage:image forState:UIControlStateNormal];
    
    self.mercurialButton.tintColor = mercurialed ? self.tintColor : UIColor.systemGrayColor;
    
    [self.mercurialButton setNeedsDisplay];
    
}

#pragma mark -

- (IBAction)mercurialButton:(id)sender {
    
    if (self.mercurialed == YES) {
        return;
    }
    
    // disable it so the action does not trigger twice.
    {
        self.mercurialButton.enabled = NO;
        self.mercurialButton.hidden = YES;
        
        self.activityIndicator.hidden = NO;
        self.activityView.hidden = NO;
        [self.activityIndicator startAnimating];
    }
    
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
                    {
                        [self.activityIndicator stopAnimating];
                        self.activityView.hidden = YES;
                        self.activityIndicator.hidden = YES;
                        
                        self.mercurialButton.enabled = !completed;
                        self.mercurialButton.hidden = NO;
                        
                    }
                    
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
