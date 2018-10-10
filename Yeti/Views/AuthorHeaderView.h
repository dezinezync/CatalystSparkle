//
//  AuthorHeaderView.h
//  Yeti
//
//  Created by Nikhil Nigade on 15/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <DZKit/DZKit.h>
#import "Author.h"

@interface AuthorHeaderView : NibView

@property (nonatomic, weak) UIImageView * _Nullable shadowImage;

@property (weak, nonatomic) IBOutlet UITextView *textview;

@property (weak, nonatomic) Author *author;

- (void)setupAppearance;

@end
