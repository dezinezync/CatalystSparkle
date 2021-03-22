//
//  Tweet.h
//  Yeti
//
//  Created by Nikhil Nigade on 28/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <DZKit/NibView.h>

//#import "Content.h"
@class Content;

#import "Paragraph.h"

@interface TweetPara : Paragraph {
    NSParagraphStyle *_paragraphStyle;
    UIFont *_bodyFont;
}

- (NSParagraphStyle * _Nonnull)paragraphStyle;

@end

@interface Tweet : NibView

- (void)configureContent:(Content * _Nonnull)content;

@property (weak, nonatomic) IBOutlet TweetPara * _Nullable textview;

- (void)addTweetForOS13:(Content * _Nonnull)content API_AVAILABLE(ios(13.0));

@end
