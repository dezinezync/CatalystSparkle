//
//  TweetImage.m
//  Yeti
//
//  Created by Nikhil Nigade on 28/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "TweetImage.h"

NSString *const kTweetCell = @"com.yeti.cell.tweetphoto";

@implementation TweetImage

//- (void)awakeFromNib
//{
//    [super awakeFromNib];
//    
//    self.backgroundColor = UIColor.redColor;
//}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.imageView.image = nil;
}

@end
