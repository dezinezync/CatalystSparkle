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

#import "BookmarksManager.h"

/*
#import <NYTPhotoViewer/NYTPhotosViewController.h>
#import <NYTPhotoViewer/NYTPhotoViewerArrayDataSource.h>
*/

@class Content;

@interface ArticleVC : UIViewController <ArticleHandler, UIViewControllerRestoration, BarPositioning, UIContextMenuInteractionDelegate> {
    BOOL _showSearchBar;
    
    UIView *_searchHighlightingRect;
    NSArray <NSValue *> *_searchingRects;
    NSInteger _searchCurrentIndex;
    CGRect _keyboardRect;
    
    UIBarButtonItem *_nextButtonItem, *_prevButtonItem;
    
#if TARGET_OS_MACCATALYST
    BOOL _shiftPressedBeforeClickingURL;
#endif
}

@property (nonatomic, assign) BOOL noAuth;

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

@property (nonatomic, weak) BookmarksManager * _Nullable bookmarksManager;

@property (nonatomic, strong, readonly) NSPointerArray * _Nullable images;

@property (nonatomic, assign, getter=isExploring) BOOL exploring;

@property (nonatomic, strong, nullable) id initialInteractivePopGestureRecognizerDelegate;

#if TARGET_OS_MACCATALYST

@property (nonatomic, assign, getter=isExternalWindow) BOOL externalWindow;

#endif

#pragma mark - Opening URLs

- (void)openLinkExternally:(NSString * _Nullable)link;

#pragma mark - Private

- (CGRect)boundingRectIn:(UITextView * _Nonnull)textview forCharacterRange:(NSRange)range;

- (void)continueActivity:(NSUserActivity * _Nonnull)activity;

- (void)saveRestorationActivity:(NSUserActivity * _Nonnull)activity;

@end
