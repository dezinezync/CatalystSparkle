//
//  ArticleVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ArticleProvider.h"
#import "ArticleHandler.h"
#import "ArticleHelperView.h"
#import "FeedItem.h"

@interface ArticleVC : UIViewController <ArticleHandler, UIViewControllerRestoration> {
    BOOL _showSearchBar;
    
    UIView *_searchHighlightingRect;
    NSArray <NSValue *> *_searchingRects;
    NSInteger _searchCurrentIndex;
    CGRect _keyboardRect;
}

- (instancetype _Nonnull)initWithItem:(FeedItem * _Nonnull)item;

@property (nonatomic, strong) FeedItem * _Nullable item;

@property (weak, nonatomic) IBOutlet UIStackView * _Nullable stackView;

@property (nonatomic, strong) UIInputView * _Nonnull searchView;

@property (nonatomic, weak) id <ArticleProvider> _Nullable providerDelegate;

@property (nonatomic, weak) ArticleHelperView *helperView;

@property (nonatomic, strong) UINotificationFeedbackGenerator *notificationGenerator;
@property (nonatomic, strong) UISelectionFeedbackGenerator *feedbackGenerator;

@property (nonatomic, weak) UISearchBar *searchBar;
@property (nonatomic, weak) UIButton *searchPrevButton, *searchNextButton;

#pragma mark - Private

- (CGRect)boundingRectIn:(UITextView *)textview forCharacterRange:(NSRange)range;

@end
