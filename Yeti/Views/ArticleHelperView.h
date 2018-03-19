//
//  ArticleHelperView.h
//  Yeti
//
//  Created by Nikhil Nigade on 19/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <DZKit/NibView.h>

@interface ArticleHelperView : NibView

@property (weak, nonatomic) IBOutlet UIButton *nextArticleButton;
@property (weak, nonatomic) IBOutlet UIButton *previousArticleButton;
@property (weak, nonatomic) IBOutlet UIButton *startOfArticle;
@property (weak, nonatomic) IBOutlet UIButton *endOfArticle;

@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;

@end
