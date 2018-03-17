//
//  ArticleVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FeedItem.h"

@interface ArticleVC : UIViewController {
    UISearchBar *_searchBar;
    UIInputView *_searchView;
    BOOL _showSearchBar;
    UIButton *_searchPrevButton, *_searchNextButton;
}

- (instancetype _Nonnull)initWithItem:(FeedItem * _Nonnull)item;

@property (nonatomic, weak) FeedItem * _Nullable item;

@property (weak, nonatomic) IBOutlet UIStackView * _Nullable stackView;

@property (nonatomic, strong) UIInputView * _Nonnull searchView;

@end
