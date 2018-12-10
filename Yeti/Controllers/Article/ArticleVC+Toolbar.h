//
//  ArticleVC+Toolbar.h
//  Yeti
//
//  Created by Nikhil Nigade on 02/12/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "ArticleVC+Keyboard.h"

@interface ArticleVC (Toolbar) <UISearchBarDelegate>

- (void)keyboardFrameChanged:(NSNotification *)note;

- (void)setupToolbar:(UITraitCollection *)newCollection;

- (void)didTapSearch;
- (void)didTapSearchNext;
- (void)didTapSearchPrevious;
- (void)didTapSearchDone;

- (void)didTapRead:(id)sender;
- (void)didTapBookmark:(id)sender;
- (void)didTapClose;

@end
