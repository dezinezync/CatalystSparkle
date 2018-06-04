//
//  ArticleHelperView.h
//  Yeti
//
//  Created by Nikhil Nigade on 19/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <DZKit/NibView.h>
#import "ArticleHandler.h"
#import "ArticleProvider.h"

@interface ArticleHelperView : NibView

@property (weak, nonatomic) IBOutlet UIStackView *stackView;

@property (weak, nonatomic) IBOutlet UIButton * _Nullable nextArticleButton;
@property (weak, nonatomic) IBOutlet UIButton * _Nullable previousArticleButton;
@property (weak, nonatomic) IBOutlet UIButton * _Nullable startOfArticle;
@property (weak, nonatomic) IBOutlet UIButton * _Nullable endOfArticle;

@property (nonatomic, strong) NSLayoutConstraint * _Nonnull bottomConstraint;

@property (nonatomic, weak) id <ArticleProvider> _Nullable providerDelegate;
@property (nonatomic, weak) id <ArticleHandler> _Nullable handlerDelegate;

- (void)updateShadowPath;

- (IBAction)didTapPreviousArticle:(UIButton *)sender;

- (IBAction)didTapNextArticle:(UIButton *)sender;

- (IBAction)didTapArticleTop:(UIButton *)sender;

- (IBAction)didTapArticleEnd:(UIButton *)sender;

@end
