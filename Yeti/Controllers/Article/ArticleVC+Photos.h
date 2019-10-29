//
//  ArticleVC+Photos.h
//  Yeti
//
//  Created by Nikhil Nigade on 04/10/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "ArticleVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface ArticleVC (Photos) <NYTPhotosViewControllerDelegate>

- (void)didTapOnImage:(UITapGestureRecognizer *)sender API_AVAILABLE(ios(13.0));

- (void)didTapOnImageWithURL:(UITapGestureRecognizer *)sender;

@end

NS_ASSUME_NONNULL_END
