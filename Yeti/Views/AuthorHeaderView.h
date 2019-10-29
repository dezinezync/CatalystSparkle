//
//  AuthorHeaderView.h
//  Yeti
//
//  Created by Nikhil Nigade on 15/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <DZKit/DZKit.h>
#import "Author.h"
#import "Feed.h"

@interface AuthorHeaderView : NibView

@property (nonatomic, weak) UIImageView * _Nullable shadowImage;

@property (weak, nonatomic) IBOutlet UILabel * _Nullable label;
@property (weak, nonatomic) IBOutlet UITextView * _Nullable textview;

@property (weak, nonatomic) Feed * _Nullable feed;
@property (weak, nonatomic) Author * _Nullable author;

- (void)setupAppearance;

@end
