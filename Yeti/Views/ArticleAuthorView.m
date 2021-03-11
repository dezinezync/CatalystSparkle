//
//  ArticleAuthorView.m
//  Yeti
//
//  Created by Nikhil Nigade on 28/03/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "ArticleAuthorView.h"
#import "TypeFactory.h"
#import "YetiConstants.h"
#import "Coordinator.h"
#import "Elytra-Swift.h"

@interface ArticleAuthorView () <UIContextMenuInteractionDelegate> {
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
        self.mercurialButton.accessibilityLabel = @"Load Full Text";
        self.mercurialButton.accessibilityValue = @"Load Full Text";
        
        if (@available(iOS 13.4, *)) {
            self.mercurialButton.pointerInteractionEnabled = YES;
        }
        
        self.activityView.hidden = YES;
        self.activityIndicator.hidden = YES;
        
        UIContextMenuInteraction *interaction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
        [self.mercurialButton addInteraction:interaction];
        
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
    
    if (mercurialed) {
        self.mercurialButton.accessibilityLabel = @"Load Article Text";
        self.mercurialButton.accessibilityValue = @"Full Article Text";
    }
    else {
        self.mercurialButton.accessibilityLabel = @"Load Full Text";
        self.mercurialButton.accessibilityValue = @"Load Full Text";
    }
    
    [self.mercurialButton setNeedsDisplay];
    
}

#pragma mark -

- (IBAction)mercurialButton:(id)sender {
    
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
                    
                    [self.activityIndicator stopAnimating];
                    self.activityView.hidden = YES;
                    self.activityIndicator.hidden = YES;
                    
                    self.mercurialButton.enabled = YES;
                    self.mercurialButton.hidden = NO;
                    
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

#pragma mark - <UIContextMenuInteractionDelegate>

- (nullable UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location {
    
    UIContextMenuConfiguration *config = nil;
    
    if (self.mercurialed) {
        
        weakify(self);
        
        config = [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
           
            UIAction *delete = [UIAction actionWithTitle:@"Delete Full Text Copy" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
                strongify(self);
                
                [self deleteCache];
                
            }];
            
            UIAction *deleteAndDownload = [UIAction actionWithTitle:@"Delete and Redownload" image:[UIImage systemImageNamed:@"arrow.triangle.2.circlepath.circle"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
                strongify(self);
                
                [self deleteCache];
                
                // tap button again
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    [self mercurialButton:self.mercurialButton];
                    
                });
                
            }];
            
            return [UIMenu menuWithTitle:@"Full-Text Content Options" children:@[delete, deleteAndDownload]];
            
        }];
        
    }
    
    return config;
    
}

- (void)deleteCache {
    
    SEL aSel = NSSelectorFromString(@"item");
    
    if (self.delegate != nil && [self.delegate respondsToSelector:aSel]) {
        
        FeedItem *item = DZS_SILENCE_CALL_TO_UNKNOWN_SELECTOR([self.delegate performSelector:aSel];);
        
        if (item == nil) {
            return;
        }
        
        // @TODO 
//        DBManager.shared.removeFullText(...)
        
        [self mercurialButton:self.mercurialButton];
        
        item.mercury = NO;
        
    }
    
}

@end
