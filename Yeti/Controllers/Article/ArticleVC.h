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

@interface ArticleVC : UIViewController <ArticleHandler> {
    UISearchBar *_searchBar;
    UIInputView *_searchView;
    BOOL _showSearchBar;
    UIButton *_searchPrevButton, *_searchNextButton;
    
    UIView *_searchHighlightingRect;
    NSArray <NSValue *> *_searchingRects;
    NSInteger _searchCurrentIndex;
    CGRect _keyboardRect;
}

- (instancetype _Nonnull)initWithItem:(FeedItem * _Nonnull)item;

@property (nonatomic, weak) FeedItem * _Nullable item;

@property (weak, nonatomic) IBOutlet UIStackView * _Nullable stackView;

@property (nonatomic, strong) UIInputView * _Nonnull searchView;

@property (nonatomic, weak) id <ArticleProvider> _Nullable providerDelegate;

@property (nonatomic, weak) ArticleHelperView *helperView;

#pragma mark - Private

- (CGRect)boundingRectIn:(UITextView *)textview forCharacterRange:(NSRange)range;

@end
