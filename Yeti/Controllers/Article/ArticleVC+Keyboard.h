//
//  ArticleVC+Keyboard.h
//  Yeti
//
//  Created by Nikhil Nigade on 04/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "ArticleVC+Photos.h"

@interface ArticleVC (Keyboard)

- (void)didTapPreviousArticle:(id)sender;

- (void)didTapNextArticle:(id)sender;

- (void)scrollDown;

- (void)scrollUp;

- (void)scrollToTop;

- (void)scrollToEnd;

- (void)navLeft;

- (void)navRight;

@end
