//
//  ArticleVC+Toolbar.h
//  Yeti
//
//  Created by Nikhil Nigade on 02/12/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "ArticleVC.h"

@interface ArticleVC (Toolbar) <UISearchBarDelegate>

- (void)setupToolbar:(UITraitCollection *)newCollection;

- (void)didTapSearch;

@end
