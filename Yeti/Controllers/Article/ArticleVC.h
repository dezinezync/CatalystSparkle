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

#import "BarPositioning.h"

@interface ArticleVC : UIViewController <ArticleHandler, UIViewControllerRestoration, BarPositioning> {
    BOOL _showSearchBar;
    
    UIView *_searchHighlightingRect;
    NSArray <NSValue *> *_searchingRects;
    NSInteger _searchCurrentIndex;
    CGRect _keyboardRect;
    
    UIBarButtonItem *_nextButtonItem, *_prevButtonItem;
}

- (instancetype _Nonnull)initWithItem:(FeedItem * _Nonnull)item;

@property (nonatomic, strong) FeedItem * _Nullable item;

@property (weak, nonatomic) IBOutlet UIStackView * _Nullable stackView;

@property (nonatomic, strong) UIInputView * _Nonnull searchView;

@property (nonatomic, weak) id <ArticleProvider> _Nullable providerDelegate;

@property (nonatomic, weak) ArticleHelperView * _Nullable helperView;

@property (nonatomic, strong) UINotificationFeedbackGenerator * _Nullable notificationGenerator;
@property (nonatomic, strong) UISelectionFeedbackGenerator * _Nullable feedbackGenerator;

@property (nonatomic, weak) UISearchBar * _Nullable searchBar;
@property (nonatomic, weak) UIButton * _Nullable searchPrevButton, * _Nullable searchNextButton;

#pragma mark - Private

- (CGRect)boundingRectIn:(UITextView * _Nonnull)textview forCharacterRange:(NSRange)range;

@end
