//
//  Tweet.h
//  Yeti
//
//  Created by Nikhil Nigade on 28/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <DZKit/NibView.h>

#import "Content.h"
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

@end
